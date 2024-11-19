'use strict';

/**
 * p2p service
 */

const { createCoreService } = require('@strapi/strapi').factories;

module.exports = createCoreService('api::p2p.p2p');
