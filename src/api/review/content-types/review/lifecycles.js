'use strict';

/**
 * review_date is the date reviews are shown and sorted by: for our own users' reviews it is the creation time,
 * for reviews copied from another monitoring (source != null) the competitors service sets the original date.
 */
module.exports = {
  beforeCreate(event) {
    const { data } = event.params;
    if (!data.review_date) data.review_date = new Date().toISOString();
  },
};
