DROP FUNCTION IF EXISTS create_store;

CREATE OR REPLACE FUNCTION create_store (
    name text,
    address text,
    user_id bigint,
    review_event_content text DEFAULT NULL,
    regular_customer_event_content text DEFAULT NULL,
    minimum_delivery_time int DEFAULT NULL,
    maximum_delivery_time int DEFAULT NULL,
    image_urls text ARRAY DEFAULT NULL,
    hashtags text ARRAY DEFAULT NULL,
    out inserted_store_id bigint
  ) language SQL AS $$ WITH inserted_store AS (
    INSERT INTO store (
        name,
        address,
        business_registration_name,
        business_registration_number,
        business_registration_address,
        business_representative_name,
        user_id,
        review_event_content,
        regular_customer_event_content,
        minimum_delivery_time,
        maximum_delivery_time,
        image_urls
      )
    VALUES (
        name,
        address,
        '상호명',
        '1502315983',
        '사업장소재지',
        '대표자',
        user_id,
        review_event_content,
        regular_customer_event_content,
        minimum_delivery_time,
        maximum_delivery_time,
        image_urls
      )
    RETURNING id
  ),
  hashtag_input (name) AS (
    SELECT unnest(hashtags)
  ),
  inserted_hashtag (id) AS (
    INSERT INTO hashtag (name)
    SELECT *
    FROM hashtag_input ON CONFLICT (name) DO NOTHING
    RETURNING id
  ),
  store_hashtag (id) AS (
    SELECT id
    FROM inserted_hashtag
    UNION ALL
    SELECT hashtag.id
    FROM hashtag_input
      JOIN hashtag USING (name)
  ),
  inserted_store_x_hashtag AS (
    INSERT INTO store_x_hashtag (store_id, hashtag_id)
    SELECT inserted_store.id,
      store_hashtag.id
    FROM inserted_store,
      store_hashtag
  )
SELECT id
FROM inserted_store;

$$;

DROP FUNCTION IF EXISTS select_insert_menu_category;

CREATE OR REPLACE FUNCTION select_insert_menu_category(_name text, OUT menu_category_id int) AS $$ BEGIN LOOP
SELECT id
FROM menu_category
WHERE name = _name INTO menu_category_id;

EXIT
WHEN FOUND;

INSERT INTO menu_category (name)
VALUES (_name) ON CONFLICT (name) DO NOTHING
RETURNING menu_category.id INTO menu_category_id;

EXIT
WHEN FOUND;

END LOOP;

END $$ LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS create_menu;

CREATE OR REPLACE FUNCTION create_menu (
    name text,
    price int,
    category_name text,
    store_id bigint,
    image_urls text ARRAY DEFAULT NULL,
    hashtags text ARRAY DEFAULT NULL,
    out inserted_menu_id bigint
  ) language SQL AS $$ WITH inserted_menu AS (
    INSERT INTO menu (name, price, category_id, store_id, image_urls)
    VALUES (
        name,
        price,
        select_insert_menu_category(category_name),
        store_id,
        image_urls
      )
    RETURNING id
  ),
  hashtag_input (name) AS (
    SELECT unnest(hashtags)
  ),
  inserted_hashtag AS (
    INSERT INTO hashtag (name)
    SELECT name
    FROM hashtag_input ON CONFLICT (name) DO NOTHING
    RETURNING id
  ),
  menu_hashtag AS (
    SELECT id
    FROM inserted_hashtag
    UNION ALL
    SELECT hashtag.id
    FROM hashtag_input
      JOIN hashtag USING (name)
  ),
  inserted_menu_x_hashtag AS (
    INSERT INTO menu_x_hashtag (menu_id, hashtag_id)
    SELECT inserted_menu.id,
      menu_hashtag.id
    FROM inserted_menu,
      menu_hashtag
  )
SELECT id
FROM inserted_menu;

$$;

DROP FUNCTION IF EXISTS toggle_user_favorite_menu;

CREATE OR REPLACE FUNCTION toggle_user_favorite_menu(_user_id bigint, _menu_id bigint) RETURNS boolean LANGUAGE plpgsql AS $$ BEGIN perform
FROM user_x_favorite_menu
WHERE user_id = _user_id
  AND menu_id = _menu_id;

IF NOT FOUND THEN
INSERT INTO user_x_favorite_menu(user_id, menu_id)
VALUES(_user_id, _menu_id);

RETURN TRUE;

ELSE
INSERT INTO deleted.user_x_favorite_menu(user_id, menu_id, creation_date)
SELECT user_id,
  menu_id,
  creation_date
FROM user_x_favorite_menu
WHERE user_id = _user_id
  AND menu_id = _menu_id;

DELETE FROM user_x_favorite_menu
WHERE user_id = _user_id
  AND menu_id = _menu_id;

RETURN FALSE;

END IF;

END;

$$;

DROP FUNCTION IF EXISTS toggle_user_favorite_store;

CREATE OR REPLACE FUNCTION toggle_user_favorite_store(_user_id bigint, _store_id bigint) RETURNS boolean LANGUAGE plpgsql AS $$ BEGIN perform
FROM user_x_favorite_store
WHERE user_id = _user_id
  AND store_id = _store_id;

IF NOT FOUND THEN
INSERT INTO user_x_favorite_store(user_id, store_id)
VALUES(_user_id, _store_id);

RETURN TRUE;

ELSE
INSERT INTO deleted.user_x_favorite_store(user_id, store_id, creation_date)
SELECT user_id,
  store_id,
  creation_date
FROM user_x_favorite_store
WHERE user_id = _user_id
  AND store_id = _store_id;

DELETE FROM user_x_favorite_store
WHERE user_id = _user_id
  AND store_id = _store_id;

RETURN FALSE;

END IF;

END;

$$;

DROP FUNCTION IF EXISTS get_total_price_from;

CREATE OR REPLACE FUNCTION get_total_price_from(
    menu_ids bigint ARRAY,
    menu_option_ids bigint ARRAY DEFAULT NULL,
    out total_price int
  ) language SQL IMMUTABLE AS $$
SELECT sum(sum)::int
FROM(
    SELECT sum(price)
    FROM menu
      JOIN (
        SELECT unnest(menu_ids) AS id
      ) AS selected_menu ON menu.id = selected_menu.id
    UNION ALL
    SELECT sum(price)
    FROM menu_option
      JOIN (
        SELECT unnest(menu_option_ids) AS id
      ) AS selected_menu_option ON menu_option.id = selected_menu_option.id
  ) AS total_selection;

$$;

DROP FUNCTION IF EXISTS get_delivery_charge_from;

CREATE OR REPLACE FUNCTION get_delivery_charge_from(
    store_id bigint,
    out delivery_charge int
  ) language SQL IMMUTABLE AS $$
SELECT delivery_charge
FROM store
WHERE id = store_id;

$$;

DROP FUNCTION IF EXISTS create_order;

CREATE OR REPLACE FUNCTION create_order (
    delivery_address varchar(64),
    payment_date timestamptz,
    user_id bigint,
    payment_id bigint,
    store_id bigint,
    menu_ids bigint ARRAY,
    menu_option_ids bigint ARRAY DEFAULT NULL,
    point_used int DEFAULT NULL,
    review_reward boolean DEFAULT NULL,
    regular_reward boolean DEFAULT NULL,
    delivery_request varchar(256) DEFAULT NULL,
    coupon_id bigint DEFAULT NULL,
    store_request varchar(256) DEFAULT NULL,
    out inserted_order_id bigint
  ) language SQL AS $$ WITH selected_menu (id) AS (
    SELECT unnest(menu_ids)
  ),
  selected_menu_option (id) AS (
    SELECT unnest(menu_option_ids)
  ),
  inserted_order AS (
    INSERT INTO "order" (
        delivery_address,
        menu_total,
        delivery_charge,
        payment_date,
        user_id,
        payment_id,
        store_id,
        point_used,
        review_reward,
        regular_reward,
        delivery_request,
        store_request,
        coupon_id
      )
    VALUES (
        delivery_address,
        get_total_price_from(menu_ids, menu_option_ids),
        get_delivery_charge_from(store_id),
        payment_date,
        user_id,
        payment_id,
        store_id,
        point_used,
        review_reward,
        regular_reward,
        delivery_request,
        store_request,
        coupon_id
      )
    RETURNING id
  ),
  update_user_point AS (
    UPDATE "user"
    SET point = point - point_used
    WHERE id = user_id
  ),
  inserted_menu_x_order AS(
    INSERT INTO menu_x_order (menu_id, order_id)
    SELECT inserted_order.id,
      selected_menu.id
    FROM inserted_order,
      selected_menu
  ),
  inserted_menu_option_x_order AS (
    INSERT INTO menu_option_x_order (menu_option_id, order_id)
    SELECT inserted_order.id,
      selected_menu_option.id
    FROM inserted_order,
      selected_menu_option
  )
SELECT id
FROM inserted_order;

$$;

DROP FUNCTION IF EXISTS create_post;

CREATE OR REPLACE FUNCTION create_post (
    content text,
    store_id bigint,
    image_urls text [] DEFAULT NULL,
    hashtags text [] DEFAULT NULL,
    out inserted_post_id bigint
  ) language SQL AS $$ WITH inserted_post AS (
    INSERT INTO post (
        content,
        store_id,
        image_urls
      )
    VALUES (content, store_id, image_urls)
    RETURNING id
  ),
  hashtag_input (name) AS (
    SELECT unnest(hashtags)
  ),
  inserted_hashtag AS (
    INSERT INTO hashtag (name)
    SELECT *
    FROM hashtag_input ON CONFLICT (name) DO NOTHING
    RETURNING id
  ),
  post_hashtag AS (
    SELECT id
    FROM inserted_hashtag
    UNION ALL
    SELECT hashtag.id
    FROM hashtag_input
      JOIN hashtag USING (name)
  ),
  inserted_post_x_hashtag AS (
    INSERT INTO post_x_hashtag (post_id, hashtag_id)
    SELECT inserted_post.id,
      post_hashtag.id
    FROM inserted_post,
      post_hashtag
  )
SELECT id
FROM inserted_post;

$$;