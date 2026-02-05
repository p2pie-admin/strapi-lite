'use strict';

/**
 * p2p-level router
 */

const { createCoreRouter } = require('@strapi/strapi').factories;

module.exports = createCoreRouter('api::p2p-level.p2p-level');
