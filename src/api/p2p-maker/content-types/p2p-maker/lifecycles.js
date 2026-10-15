'use strict';

const { ApplicationError } = require('@strapi/utils').errors;

/**
 * The maker's Telegram username is private: only the bot knows it. The public identity is `slug` (URL and handle on
 * the site) plus `telegram_name` (display name). Neither may equal or contain the Telegram username, whatever the case.
 */
const UID = 'api::p2p-maker.p2p-maker';
const norm = (value) => String(value || '').toLowerCase().replace(/^@/, '').replace(/[^a-z0-9а-яё]/g, '');
const LETTERS = 'abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ';
const randomSlug = () => Array.from({ length: 6 }, () => LETTERS[Math.floor(Math.random() * LETTERS.length)]).join('');

const reveals = (value, username) => {
  const v = norm(value);
  const u = norm(username);
  return Boolean(v && u && (v === u || (u.length >= 4 && v.includes(u))));
};

const check = async (data, current, id) => {
  const username = data.telegram_username !== undefined ? data.telegram_username : current && current.telegram_username;
  const slug = data.slug !== undefined ? data.slug : current && current.slug;
  const name = data.telegram_name !== undefined ? data.telegram_name : current && current.telegram_name;
  if (reveals(slug, username)) throw new ApplicationError('slug must not match the Telegram username');
  if (reveals(name, username)) throw new ApplicationError('name must not match the Telegram username');
  if (data.slug !== undefined && data.slug !== null) {
    if (!/^[A-Za-z0-9_]{3,32}$/.test(data.slug)) throw new ApplicationError('slug: 3-32 latin letters, digits or _');
    const twin = await strapi.db.query(UID).findOne({ where: { slug: { $eqi: data.slug }, ...(id ? { id: { $ne: id } } : {}) } });
    if (twin) throw new ApplicationError('slug is taken');
  }
};

module.exports = {
  async beforeCreate(event) {
    const { data } = event.params;
    if (!data.slug) {
      for (let i = 0; i < 20; i++) {
        const candidate = randomSlug();
        if (!(await strapi.db.query(UID).findOne({ where: { slug: { $eqi: candidate } } }))) {
          data.slug = candidate;
          break;
        }
      }
    }
    await check(data, null, null);
  },
  async beforeUpdate(event) {
    const { data, where } = event.params;
    if (data.slug === undefined && data.telegram_name === undefined && data.telegram_username === undefined) return;
    const current = where && where.id ? await strapi.db.query(UID).findOne({ where: { id: where.id } }) : null;
    await check(data, current, current && current.id);
  },
};
