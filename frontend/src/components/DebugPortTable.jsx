function DebugPortTable({ rows }) {
  return (
    <table className="w-full border mt-4 text-sm">
      <thead className="bg-gray-100">
        <tr>
          <th className="border p-2 text-left">Server</th>
          <th className="border p-2 text-left">Port</th>
          <th className="border p-2 text-left">Status</th>
        </tr>
      </thead>
      <tbody>
        {rows.map((row, i) => (
          <tr key={i} className="even:bg-gray-50">
            <td className="border p-2">{row.server}</td>
            <td className="border p-2">{row.port}</td>
            <td className="border p-2">{row.status}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}

export default DebugPortTable;

