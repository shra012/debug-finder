function Header() {
    return (
        <header className="bg-indigo-600 text-white shadow sticky top-0 z-10">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="flex items-center justify-between h-16">
                    <div className="flex items-center space-x-4">
                        <span className="text-xl font-semibold tracking-wide">MIG Debug Finder</span>
                    </div>
                </div>
            </div>
        </header>
    );
}

export default Header;

