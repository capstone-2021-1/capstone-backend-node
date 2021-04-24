import { store } from '../store/ORM'

export const menu: any = {
  id: '',
  creationDate: '',
  modificationDate: '',
  name: '',
  price: 0,
  category: '',
  deliciousReviewCount: 0,
  deliciousReviewRatio: 0,
  fineReviewCount: 0,
  fineReviewRatio: 0,
  positiveReviewRatio: 0,
  badReviewCount: 0,
  badReviewRatio: 0,
  newOrderCount: 0,
  newOrderRatio: 0,
  reorderCount: 0,
  reorderRatio: 0,
  newCustomerCount: 0,
  newCustomerRatio: 0,
  regularCustomerCount: 0,
  regularCustomerRatio: 0,
  favoriteCount: 0,
  clickCount: 0,
  storePostCount: 0,
  isDiscounted: false,
  canBePicked: false,
  canBeReserved: false,
  storeId: '',

  favorite: false,
  store: store,
}

function returnZeroWhenZeroDivision(numerator: number, denominator: number) {
  return denominator !== 0 ? numerator / denominator : 0
}

export function menuORM(menu: any) {
  return {
    id: menu.id,
    creationDate: menu.creation_date,
    modificationDate: menu.modification_date,
    deliciousReviewCount: menu.delicious_review_count,
    deliciousReviewRatio: returnZeroWhenZeroDivision(
      menu.delicious_review_count,
      menu.delicious_review_count + menu.fine_review_count + menu.bad_review_count
    ),
    fineReviewCount: menu.fine_review_count,
    fineReviewRatio: returnZeroWhenZeroDivision(
      menu.fine_review_count,
      menu.delicious_review_count + menu.fine_review_count + menu.bad_review_count
    ),
    positiveReviewRatio: returnZeroWhenZeroDivision(
      menu.delicious_review_count + menu.fine_review_count,
      menu.delicious_review_count + menu.fine_review_count + menu.bad_review_count
    ),
    badReviewCount: menu.bad_review_count,
    badReviewRatio: returnZeroWhenZeroDivision(
      menu.bad_review_count,
      menu.delicious_review_count + menu.fine_review_count + menu.bad_review_count
    ),
    newOrderCount: menu.new_order_count,
    newOrderRatio: returnZeroWhenZeroDivision(
      menu.new_order_count,
      menu.reorder_count + menu.new_order_count
    ),
    reorderCount: menu.reorder_count,
    reorderRatio: returnZeroWhenZeroDivision(
      menu.reorder_count,
      menu.reorder_count + menu.new_order_count
    ),
    newCustomerCount: menu.new_customer_count,
    newCustomerRatio: returnZeroWhenZeroDivision(
      menu.new_customer_count,
      menu.new_customer_count + menu.regular_customer_count
    ),
    regularCustomerCount: menu.regular_customer_count,
    regularCustomerRatio: returnZeroWhenZeroDivision(
      menu.regular_customer_count,
      menu.new_customer_count + menu.regular_customer_count
    ),
    favoriteCount: menu.favorite_count,
    clickCount: menu.click_count,
    storePostCount: menu.store_post_count,
    isDiscounted: menu.is_discounted,
    canBePicked: menu.can_be_picked,
    canBeReserved: menu.can_be_reserved,
    name: menu.name,
    price: menu.price,
    category: menu.category,
    storeId: menu.store_id,
    imageUrls: menu.image_urls,

    favorite: false,
    store: store,
  }
}