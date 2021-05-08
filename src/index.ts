/* eslint-disable import/first */
/* eslint-disable no-console */
import dotenv from 'dotenv'

if (process.env.NODE_ENV === 'production') dotenv.config()
else dotenv.config({ path: '.env.development' })

import { server } from './apollo/server'
import { connectDatabase } from './database/postgres'

connectDatabase()

server
  .listen({ port: process.env.PORT || 4000 })
  .then(({ url }) => console.log(`🚀  Server ready at ${url}`))
  .catch((reason) => console.error(reason))
