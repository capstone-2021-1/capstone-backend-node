select
  id,
  password_hash_hash
from
  "user"
where
  email = $1;
