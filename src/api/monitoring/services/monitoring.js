'use strict';

/**
 * monitoring service
 */

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::monitoring.monitoring');
