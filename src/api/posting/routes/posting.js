'use strict';

/**
 * posting route
 */

const { createCoreRouter } = require('@strapi/strapi').factories;

module.exports = createCoreRouter('api::posting.posting');
