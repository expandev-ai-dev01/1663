export const HomePage = () => {
  return (
    <div className="space-y-6">
      <div className="rounded-lg bg-white p-6 shadow">
        <h2 className="text-xl font-semibold text-gray-900">Welcome to AutoClean</h2>
        <p className="mt-2 text-gray-600">
          A simple script that identifies and removes temporary or duplicate files from a selected
          folder.
        </p>
      </div>

      <div className="rounded-lg bg-white p-6 shadow">
        <h3 className="text-lg font-semibold text-gray-900">Features</h3>
        <ul className="mt-4 space-y-2">
          <li className="flex items-start">
            <span className="mr-2 text-blue-600">•</span>
            <span className="text-gray-600">Identify and remove temporary files automatically</span>
          </li>
          <li className="flex items-start">
            <span className="mr-2 text-blue-600">•</span>
            <span className="text-gray-600">
              Detect common temporary file extensions (.tmp, .temp, .cache)
            </span>
          </li>
          <li className="flex items-start">
            <span className="mr-2 text-blue-600">•</span>
            <span className="text-gray-600">Free up disk space efficiently</span>
          </li>
        </ul>
      </div>

      <div className="rounded-lg bg-blue-50 p-6">
        <p className="text-center text-gray-700">
          Select a folder to start cleaning temporary files
        </p>
        <div className="mt-4 flex justify-center">
          <button className="rounded-md bg-blue-600 px-6 py-2 text-white hover:bg-blue-700">
            Select Folder
          </button>
        </div>
      </div>
    </div>
  );
};

export default HomePage;
