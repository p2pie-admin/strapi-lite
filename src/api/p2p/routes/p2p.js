'use strict';

/**
 * p2p router
 */

const { createCoreRouter } = require('@strapi/strapi').factories;

module.exports = createCoreRouter('api::p2p.p2p');
