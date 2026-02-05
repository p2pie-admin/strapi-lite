'use strict';

/**
 * p2p-level service
 */

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::p2p-level.p2p-level');
