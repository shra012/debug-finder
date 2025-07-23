import Header from './Header';

function Layout({ children }) {
  return (
    <div className="min-h-screen bg-white text-gray-900">
      <Header />
      <main className="max-w-4xl mx-auto py-10 px-4">{children}</main>
    </div>
  );
}

export default Layout;

