'use strict';

/**
 * Reviews store the author's IP, user agent, location, browser fingerprint and contacts. Anonymous (Public role)
 * API requests must never see or filter by them; authenticated callers (our server, bot, competitors service,
 * admin panel) keep full access. Done in an entityService decorator so REST, GraphQL and nested relations
 * (exchanger.reviews, p2p-maker.reviews) are all covered in one place.
 */
const crypto = require('crypto');

const REVIEW_UID = 'api::review.review';
const HIDDEN = ['telegram', 'whatsapp', 'userAgent', 'location'];
const NO_FILTER = new Set(['ipAddress', 'fingerprint', ...HIDDEN]);

// Same masking the front applies (services/maskIP.ts), so masked values stay comparable there.
const maskIP = (ip) => {
  if (ip == null) return null;
  const s = String(ip).trim();
  return s.length <= 3 ? '***' : `${s.slice(0, -3)}***`;
};

// Stable public stand-in for the fingerprint (the front only uses it as an avatar seed).
const hashFingerprint = (fp) =>
  fp == null ? null : crypto.createHash('sha256').update(`review-fp:${fp}`).digest('hex').slice(0, 16);

const isPublicRequest = () => {
  const ctx = strapi.requestContext && strapi.requestContext.get();
  if (!ctx || !ctx.state) return false; // cron, scripts, lifecycles
  return !(ctx.state.user || (ctx.state.auth && ctx.state.auth.credentials));
};

const relationTarget = (uid, key) => {
  const model = uid && strapi.getModel(uid);
  const attr = model && model.attributes[key];
  return attr && attr.type === 'relation' ? attr.target : null;
};

const maskEntity = (uid, data) => {
  if (!data || typeof data !== 'object') return data;
  if (Array.isArray(data)) return data.map((item) => maskEntity(uid, item));
  if (uid === REVIEW_UID) {
    if ('ipAddress' in data) data.ipAddress = maskIP(data.ipAddress);
    if ('fingerprint' in data) data.fingerprint = hashFingerprint(data.fingerprint);
    for (const key of HIDDEN) if (key in data) data[key] = null;
  }
  for (const key of Object.keys(data)) {
    const target = relationTarget(uid, key);
    if (target && data[key] && typeof data[key] === 'object') maskEntity(target, data[key]);
  }
  return data;
};

const findForbiddenFilter = (uid, filters) => {
  if (!filters || typeof filters !== 'object') return null;
  if (Array.isArray(filters)) {
    for (const f of filters) {
      const hit = findForbiddenFilter(uid, f);
      if (hit) return hit;
    }
    return null;
  }
  for (const [key, value] of Object.keys(filters).map((k) => [k, filters[k]])) {
    if (key.startsWith('$')) {
      const hit = findForbiddenFilter(uid, value);
      if (hit) return hit;
      continue;
    }
    if (uid === REVIEW_UID && NO_FILTER.has(key)) {
      // An exact fingerprint match reveals nothing new (the front looks up its "test" review this way).
      const exactOnly = key === 'fingerprint' && value && typeof value === 'object' && Object.keys(value).every((op) => op === '$eq');
      if (!exactOnly) return key;
    }
    const target = relationTarget(uid, key);
    if (target) {
      const hit = findForbiddenFilter(target, value);
      if (hit) return hit;
    }
  }
  return null;
};

const guardParams = (uid, params) => {
  const hit = params && findForbiddenFilter(uid, params.filters);
  if (hit) {
    const { ForbiddenError } = require('@strapi/utils').errors;
    throw new ForbiddenError(`Filtering by ${hit} is not allowed`);
  }
};

module.exports = (strapiInstance) => {
  strapiInstance.entityService.decorate((service) => ({
    ...service,
    async findMany(uid, params) {
      if (!isPublicRequest()) return service.findMany.call(this, uid, params);
      guardParams(uid, params);
      return maskEntity(uid, await service.findMany.call(this, uid, params));
    },
    async findPage(uid, params) {
      if (!isPublicRequest()) return service.findPage.call(this, uid, params);
      guardParams(uid, params);
      const page = await service.findPage.call(this, uid, params);
      if (page && page.results) maskEntity(uid, page.results);
      return page;
    },
    async findWithRelationCountsPage(uid, params) {
      if (!isPublicRequest()) return service.findWithRelationCountsPage.call(this, uid, params);
      guardParams(uid, params);
      const page = await service.findWithRelationCountsPage.call(this, uid, params);
      if (page && page.results) maskEntity(uid, page.results);
      return page;
    },
    async findOne(uid, id, params) {
      if (!isPublicRequest()) return service.findOne.call(this, uid, id, params);
      guardParams(uid, params);
      return maskEntity(uid, await service.findOne.call(this, uid, id, params));
    },
    async count(uid, params) {
      if (isPublicRequest()) guardParams(uid, params);
      return service.count.call(this, uid, params);
    },
    async load(uid, entity, field, params) {
      if (!isPublicRequest()) return service.load.call(this, uid, entity, field, params);
      const target = relationTarget(uid, field);
      guardParams(target, params);
      return maskEntity(target, await service.load.call(this, uid, entity, field, params));
    },
  }));
};

