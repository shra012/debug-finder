import { useEffect, useState } from 'react';
import DebugPortTable from './components/DebugPortTable';
import Loading from './components/Loading';
import Error from './components/Error';

function DebugPorts() {
  const [ports, setPorts] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetch('/debug-ports')
      .then((res) => {
        if (!res.ok) throw new Error('Failed to fetch debug ports');
        return res.json();
      })
      .then((data) => {
        setPorts(data);
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message);
        setLoading(false);
      });
  }, []);

  if (loading) return <Loading message="Loading debug ports..." />;
  if (error) return <Error message={error} />;
  if (!ports || typeof ports !== 'object' || Object.keys(ports).length === 0) {
    return <p>No debug port data.</p>;
  }

  // Render a table: Server | Port | Status
  const rows = [];
  Object.entries(ports).forEach(([server, portMap]) => {
    Object.entries(portMap).forEach(([port, status]) => {
      rows.push({ server, port, status });
    });
  });

  return (
    <div>
      <h2 className="text-xl font-semibold mb-2">Used Debug Ports</h2>
      <DebugPortTable rows={rows} />
    </div>
  );
}

export default DebugPorts;
