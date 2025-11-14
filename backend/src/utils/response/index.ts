/**
 * @summary
 * Success response interface
 *
 * @interface SuccessResponse
 */
export interface SuccessResponse<T> {
  success: true;
  data: T;
  metadata?: {
    page?: number;
    pageSize?: number;
    total?: number;
    timestamp: string;
  };
}

/**
 * @summary
 * Error response interface
 *
 * @interface ErrorResponse
 */
export interface ErrorResponse {
  success: false;
  error: {
    code: string;
    message: string;
    details?: any;
  };
  timestamp: string;
}

/**
 * @summary
 * Creates a success response object
 *
 * @function successResponse
 * @module utils
 *
 * @param {T} data - Response data
 * @param {object} metadata - Optional metadata
 *
 * @returns {SuccessResponse<T>} Success response object
 */
export function successResponse<T>(data: T, metadata?: any): SuccessResponse<T> {
  return {
    success: true,
    data,
    metadata: metadata
      ? { ...metadata, timestamp: new Date().toISOString() }
      : { timestamp: new Date().toISOString() },
  };
}

/**
 * @summary
 * Creates an error response object
 *
 * @function errorResponse
 * @module utils
 *
 * @param {string} message - Error message
 * @param {string} code - Error code
 * @param {any} details - Optional error details
 *
 * @returns {ErrorResponse} Error response object
 */
export function errorResponse(
  message: string,
  code: string = 'ERROR',
  details?: any
): ErrorResponse {
  return {
    success: false,
    error: {
      code,
      message,
      details,
    },
    timestamp: new Date().toISOString(),
  };
}
