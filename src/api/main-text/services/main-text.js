'use strict';

/**
 * main-text service
 */

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::main-text.main-text');
