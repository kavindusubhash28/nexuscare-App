import { Outlet } from "react-router-dom";
import Sidebar from "./Sidebar";
import Topbar from "./Topbar";
import "../styles/portal.css";

export default function AppLayout() {
  return (
    <div className="lb-dash-root">
      <Sidebar />
      <div className="lb-main-area">
        <Topbar />
        <div className="lb-content">
          <div className="lb-page-body">
            <Outlet />
          </div>
        </div>
      </div>
    </div>
  );
}