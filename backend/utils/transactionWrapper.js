/**
 * Transaction Wrapper Utility
 * Provides consistent transaction handling with automatic rollback and connection release
 */

const { db } = require("../config/db");

/**
 * Execute a database operation within a transaction
 * Automatically handles connection acquisition, transaction management, and cleanup
 * 
 * @param {Function} callback - Async function that receives the connection and executes queries
 * @param {Object} options - Configuration options
 * @param {string} options.isolationLevel - Transaction isolation level (default: 'READ COMMITTED')
 * @param {number} options.retryCount - Number of retries for deadlock scenarios (default: 3)
 * @param {number} options.retryDelay - Initial delay between retries in ms (default: 50)
 * @param {Object} logger - Logger instance for error logging
 * @returns {Promise<any>} Result from the callback function
 * @throws {Error} If transaction fails after all retries
 */
async function withTransaction(callback, options = {}, logger = null) {
  const {
    isolationLevel = 'READ COMMITTED',
    retryCount = 3,
    retryDelay = 50,
  } = options;

  let attempt = 0;
  let lastError = null;

  while (attempt < retryCount) {
    attempt++;
    let conn = null;

    try {
      // Acquire connection from pool
      conn = await db.getConnection();

      // Set isolation level if specified
      if (isolationLevel) {
        await conn.query(`SET TRANSACTION ISOLATION LEVEL ${isolationLevel}`);
      }

      // Begin transaction
      await conn.beginTransaction();

      // Execute callback with connection
      const result = await callback(conn);

      // Commit transaction
      await conn.commit();

      // Return result
      return result;

    } catch (err) {
      // Rollback transaction on error
      if (conn) {
        try {
          await conn.rollback();
        } catch (rollbackErr) {
          if (logger) {
            logger.error("Transaction rollback failed", { 
              error: rollbackErr.message, 
              originalError: err.message 
            });
          }
        }
      }

      lastError = err;

      // Check if error is retryable (deadlock, lock timeout)
      const isRetryable = isRetryableError(err);
      
      if (isRetryable && attempt < retryCount) {
        // Log retry attempt
        if (logger) {
          logger.warn(`Transaction failed (attempt ${attempt}/${retryCount}), retrying...`, {
            error: err.message,
            code: err.code,
            sqlState: err.sqlState,
          });
        }

        // Wait before retry with exponential backoff
        const delay = retryDelay * Math.pow(2, attempt - 1);
        await sleep(delay);
        
        continue; // Retry
      }

      // Not retryable or max retries reached, throw error
      throw err;

    } finally {
      // Always release connection back to pool
      if (conn) {
        conn.release();
      }
    }
  }

  // If we get here, all retries failed
  throw lastError;
}

/**
 * Check if database error is retryable
 * @param {Error} error - Database error
 * @returns {boolean} True if error is retryable
 */
function isRetryableError(error) {
  if (!error || !error.code) return false;

  const retryableCodes = [
    'ER_LOCK_DEADLOCK',          // Deadlock detected
    'ER_LOCK_WAIT_TIMEOUT',      // Lock wait timeout
    'ETIMEDOUT',                 // Connection timeout
    'ECONNRESET',                // Connection reset
    'ER_CON_COUNT_ERROR',        // Too many connections (temporary)
  ];

  return retryableCodes.includes(error.code);
}

/**
 * Sleep utility for retry delays
 * @param {number} ms - Milliseconds to sleep
 * @returns {Promise<void>}
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Execute multiple queries in a single transaction
 * Useful for batch operations
 * 
 * @param {Array<{query: string, params: Array}>} queries - Array of query objects
 * @param {Object} options - Transaction options
 * @param {Object} logger - Logger instance
 * @returns {Promise<Array>} Array of query results
 */
async function executeInTransaction(queries, options = {}, logger = null) {
  return withTransaction(async (conn) => {
    const results = [];

    for (const { query, params } of queries) {
      const [result] = await conn.query(query, params);
      results.push(result);
    }

    return results;
  }, options, logger);
}

module.exports = {
  withTransaction,
  executeInTransaction,
  isRetryableError,
};
