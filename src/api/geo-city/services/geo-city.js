'use strict';

/**
 * geo-city service
 */

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::geo-city.geo-city');
