'use strict';

const { ApplicationError } = require('@strapi/utils').errors;

/**
 * The maker's Telegram username is private: only the bot knows it. The public identity is `slug` (URL and handle on
 * the site) plus `telegram_name` (display name). Neither may equal or contain the Telegram username, whatever the case.
 */
const UID = 'api::p2p-maker.p2p-maker';
const norm = (value) => String(value || '').toLowerCase().replace(/^@/, '').replace(/[^a-z0-9а-яё]/g, '');
// Public id = 8 random digits: letters could spell (or be taken for) a nickname, digits cannot (owner 2026-10-16).
const randomSlug = () => String(10000000 + Math.floor(Math.random() * 90000000));

const reveals = (value, username) => {
  const v = norm(value);
  const u = norm(username);
  return Boolean(v && u && (v === u || (u.length >= 4 && v.includes(u))));
};

// Makers write their own description; any mention of the username (or a t.me link to it) becomes the literal @*****.
const escapeRe = (value) => value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const maskDescription = (data, username) => {
  if (typeof data.description !== 'string' || !username || String(username).length < 3) return;
  const u = escapeRe(String(username).replace(/^@/, ''));
  data.description = data.description
    .replace(new RegExp(`(https?:\\/\\/)?(www\\.)?(t\\.me|telegram\\.me)\\/${u}\\b`, 'gi'), '@*****')
    .replace(new RegExp(`@?${u}`, 'gi'), '@*****');
};

const check = async (data, current, id) => {
  const username = data.telegram_username !== undefined ? data.telegram_username : current && current.telegram_username;
  const slug = data.slug !== undefined ? data.slug : current && current.slug;
  const name = data.telegram_name !== undefined ? data.telegram_name : current && current.telegram_name;
  maskDescription(data, username);
  if (reveals(slug, username)) throw new ApplicationError('slug must not match the Telegram username');
  if (reveals(name, username)) throw new ApplicationError('name must not match the Telegram username');
  if (data.slug !== undefined && data.slug !== null) {
    if (!/^[1-9][0-9]{7}$/.test(String(data.slug))) throw new ApplicationError('slug: 8 random digits');
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
    if (
      data.slug === undefined &&
      data.telegram_name === undefined &&
      data.telegram_username === undefined &&
      data.description === undefined
    )
      return;
    const current = where && where.id ? await strapi.db.query(UID).findOne({ where: { id: where.id } }) : null;
    await check(data, current, current && current.id);
  },
};
