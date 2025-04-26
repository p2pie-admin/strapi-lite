'use strict';

/**
 * monitoring controller
 */

const { createCoreController } = require('@strapi/strapi').factories;

module.exports = createCoreController('api::monitoring.monitoring');
