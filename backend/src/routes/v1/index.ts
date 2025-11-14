import { Router } from 'express';
import externalRoutes from '@/routes/v1/externalRoutes';
import internalRoutes from '@/routes/v1/internalRoutes';

const router = Router();

/**
 * @summary
 * External (public) routes - /api/v1/external/...
 */
router.use('/external', externalRoutes);

/**
 * @summary
 * Internal (authenticated) routes - /api/v1/internal/...
 */
router.use('/internal', internalRoutes);

export default router;
