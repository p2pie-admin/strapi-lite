'use strict';

/**
 * exchanger service.
 */

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::exchanger.exchanger');
