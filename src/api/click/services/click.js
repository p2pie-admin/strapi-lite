'use strict';

/**
 * click service
 */

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::click.click');
