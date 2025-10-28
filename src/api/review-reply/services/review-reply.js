'use strict';

/**
 * review-reply service
 */

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::review-reply.review-reply');
