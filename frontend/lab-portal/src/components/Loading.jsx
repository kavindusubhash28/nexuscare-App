// Minor update for Git tracking - loading component
export default function Loading({ label = "Loading..." }) {
  return (
    <div style={{ padding: 20 }}>
      {label}
    </div>
  );
}