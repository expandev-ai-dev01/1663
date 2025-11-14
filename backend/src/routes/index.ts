import { Router } from 'express';
import v1Routes from '@/routes/v1';

const router = Router();

/**
 * @summary
 * API Version 1 routes
 */
router.use('/v1', v1Routes);

export default router;
