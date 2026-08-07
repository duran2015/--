import { useAppStore } from "../../store";
import { AccountSecurityPage } from "../../components/AccountSecurityPage";

export function AccountSecurity() {
  const { popView } = useAppStore();

  return (
    <AccountSecurityPage onBack={popView} />
  );
}
