'use strict';

/**
 * posting-platform service
 */

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::posting-platform.posting-platform');
