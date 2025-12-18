import React from 'react';

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props);
    this.state = { hasError: false, error: null, errorInfo: null };
  }

  static getDerivedStateFromError(error) {
    // Update state so the next render will show the fallback UI
    return { hasError: true };
  }

  componentDidCatch(error, errorInfo) {
    console.error('ErrorBoundary caught an error:', error, errorInfo);

    // PRO TIP: Auto-reload if the error is a "ChunkLoadError"
    // (This happens when you deploy a new version and the user clicks an old link)
    if (error.message && (error.message.includes('Loading chunk') || error.message.includes('missing'))) {
       window.location.reload();
       return;
    }

    this.setState({
      error: error,
      errorInfo: errorInfo
    });

    // Show toast if available
    if (this.props.onToast) {
      this.props.onToast('Something went wrong with the interface.', 'error');
    }
  }

  handleReset = () => {
    this.setState({ hasError: false, error: null, errorInfo: null });
    // Optional: Redirect to dashboard on reset to be safe
    if (window.location.pathname !== '/') {
        window.location.href = '/';
    }
  };

  render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-screen flex items-center justify-center bg-gray-50 px-4 sm:px-6 lg:px-8">
          <div className="max-w-md w-full bg-white shadow-xl rounded-xl p-8 border border-gray-100 text-center">
            
            <div className="mx-auto flex items-center justify-center h-16 w-16 rounded-full bg-red-100 mb-6">
              <svg className="h-8 w-8 text-red-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 16.5c-.77.833.192 2.5 1.732 2.5z" />
              </svg>
            </div>

            <h3 className="text-xl font-bold text-gray-900 mb-2">Something went wrong</h3>
            <p className="text-gray-500 mb-6">
              The application encountered an unexpected error. We apologize for the inconvenience.
            </p>

            <div className="flex flex-col space-y-3">
              <button
                onClick={() => window.location.reload()}
                className="w-full bg-indigo-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 transition-colors"
              >
                Reload Page
              </button>
              
              <button
                onClick={this.handleReset}
                className="w-full bg-white border border-gray-300 text-gray-700 px-4 py-2 rounded-lg text-sm font-medium hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-gray-500 transition-colors"
              >
                Try to Recover
              </button>
            </div>

            {/* Developer Details - Only shows in development mode */}
            {process.env.NODE_ENV === 'development' && this.state.error && (
              <details className="mt-6 text-left border-t pt-4">
                <summary className="cursor-pointer text-xs text-gray-400 hover:text-gray-600 outline-none">
                  Show Error Details
                </summary>
                <div className="mt-2 text-xs bg-gray-100 p-3 rounded-md overflow-auto max-h-48 text-red-800 font-mono">
                  <p className="font-bold mb-1">{this.state.error.toString()}</p>
                  <p>{this.state.errorInfo?.componentStack}</p>
                </div>
              </details>
            )}
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}

export default ErrorBoundary;