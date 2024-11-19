'use strict';

/**
 * parameter service
 */

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::parameter.parameter');
