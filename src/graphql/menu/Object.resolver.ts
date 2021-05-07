import { MenuResolvers } from 'src/graphql/generated/graphql'
import { importSQL } from '../../utils/commons'
import { poolQuery } from '../../database/postgres'
import { storeFieldColumnMapping, storeORM } from '../store/ORM'
import { selectColumnFromField } from '../../utils/ORM'
import format from 'pg-format'

const menuCategory = importSQL(__dirname, 'sql/menuCategory.sql')
const menuFavorite = importSQL(__dirname, 'sql/menuFavorite.sql')
const menuStore = importSQL(__dirname, 'sql/menuStore.sql')
const menuHashtags = importSQL(__dirname, 'sql/menuHashtags.sql')

export const Menu: MenuResolvers = {
  category: async ({ categoryId }) => {
    const { rows } = await poolQuery(await menuCategory, [categoryId])

    return rows[0].name
  },

  favorite: async ({ id }, __, { user }) => {
    if (!user) return false

    const { rowCount } = await poolQuery(await menuFavorite, [user.id, id])

    return !!rowCount
  },

  store: async ({ storeId }, _, __, info) => {
    const columns = selectColumnFromField(info, storeFieldColumnMapping)

    const { rows } = await poolQuery(format(await menuStore, columns), [storeId])

    return storeORM(rows[0])
  },

  hashtags: async ({ id }) => {
    const { rows } = await poolQuery(await menuHashtags, [id])

    return rows.map((row) => row.name)
  },
}
