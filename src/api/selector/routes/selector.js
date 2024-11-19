'use strict';

/**
 * selector router.
 */

const { createCoreRouter } = require('@strapi/strapi').factories;

module.exports = createCoreRouter('api::selector.selector');
