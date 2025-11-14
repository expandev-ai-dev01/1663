import { getLoadingSpinnerClassName } from './variants';
import type { LoadingSpinnerProps } from './types';

export const LoadingSpinner = (props: LoadingSpinnerProps) => {
  const { size = 'md', className } = props;

  return (
    <div className="flex items-center justify-center p-4">
      <div className={getLoadingSpinnerClassName({ size, className })} />
    </div>
  );
};
