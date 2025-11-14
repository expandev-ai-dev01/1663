/**
 * @summary
 * Global test environment setup
 *
 * @module tests
 */

import { closePool } from '@/instances/database';

/**
 * @summary
 * Cleanup after all tests
 */
afterAll(async () => {
  await closePool();
});
