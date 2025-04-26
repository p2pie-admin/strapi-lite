'use strict';

/**
 * monitoring router
 */

const { createCoreRouter } = require('@strapi/strapi').factories;

module.exports = createCoreRouter('api::monitoring.monitoring');
