import React, { useState } from 'react';
import { 
  ArrowLeft, Wallet, Clock, CheckCircle2, XCircle, CreditCard, Building2, 
  Info, History, FileText, ChevronRight, X, Plus, Building, Phone, User, Check, LockKeyhole, UnlockKeyhole
} from 'lucide-react';
import { ConsultantProfile, BankAccount, WithdrawalRecord, BillRecord, BillRecordStatus, Order } from '../../types';
import { INITIAL_BANK_ACCOUNTS, INITIAL_WITHDRAWAL_RECORDS, INITIAL_BILL_RECORDS } from '../../data/mockData';
import { useAppStore } from '../../client-app/store';

interface IncomeViewProps {
  consultant: ConsultantProfile;
  isMockEmpty?: boolean;
  onClose: () => void;
  onOpenSessionReview?: (draftId: string) => void;
  onOpenOrderInfo?: (order: Order) => void;
}

export const IncomeView: React.FC<IncomeViewProps> = ({ consultant, isMockEmpty, onClose, onOpenSessionReview, onOpenOrderInfo }) => {
  const workflow = useAppStore((state) => state.consultationWorkflow);
  const orders = useAppStore((state) => state.orders);
  const [bankAccounts, setBankAccounts] = useState<BankAccount[]>(isMockEmpty ? [] : INITIAL_BANK_ACCOUNTS);
  const [withdrawalRecords, setWithdrawalRecords] = useState<WithdrawalRecord[]>(isMockEmpty ? [] : INITIAL_WITHDRAWAL_RECORDS);
  const [billRecords, setBillRecords] = useState<BillRecord[]>(isMockEmpty ? [] : INITIAL_BILL_RECORDS);
  const [withdrawableBalance, setWithdrawableBalance] = useState<number>(consultant.earnings.withdrawable);

  const [settlementSubTab, setSettlementSubTab] = useState<'bills' | 'withdrawals'>('bills');
  const [billStatusFilter, setBillStatusFilter] = useState<'all' | 'settled' | 'pending_settlement' | 'refunded'>('all');

  const [showAccountsView, setShowAccountsView] = useState<boolean>(false);
  const [showAddAccountModal, setShowAddAccountModal] = useState<boolean>(false);
  const [showRulesModal, setShowRulesModal] = useState<boolean>(false);
  const [showWithdrawModal, setShowWithdrawModal] = useState<boolean>(false);
  const [activeWithdrawalDetail, setActiveWithdrawalDetail] = useState<WithdrawalRecord | null>(null);

  const [withdrawAmountInput, setWithdrawAmountInput] = useState<string>('1000');
  const [selectedAccountId, setSelectedAccountId] = useState<string>(INITIAL_BANK_ACCOUNTS[0]?.id || '');

  const [newBankName, setNewBankName] = useState<string>('');
  const [newBranchName, setNewBranchName] = useState<string>('');
  const [newCardNumber, setNewCardNumber] = useState<string>('');
  const [newAccountHolder, setNewAccountHolder] = useState<string>(consultant.name);

  const handleApplyWithdraw = (e: React.FormEvent) => {
    e.preventDefault();
    const amountNum = parseFloat(withdrawAmountInput);
    if (isNaN(amountNum) || amountNum < 100) {
      alert('提现单笔金额不能低于 ¥100.00');
      return;
    }
    if (amountNum > withdrawableBalance) {
      alert('提现金额超出当前可提现余额！');
      return;
    }

    const targetAccount = bankAccounts.find(a => a.id === selectedAccountId) || bankAccounts[0];
    const now = new Date();
    const formattedTime = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')} ${String(now.getHours()).padStart(2, '0')}:${String(now.getMinutes()).padStart(2, '0')}`;

    const newRecord: WithdrawalRecord = {
      id: `wd_${Date.now()}`,
      withdrawNo: `WD${now.getFullYear()}${String(now.getMonth()+1).padStart(2, '0')}${String(now.getDate()).padStart(2, '0')}${String(Math.floor(Math.random()*900)+100)}`,
      amount: amountNum,
      bankAccount: {
        bankName: targetAccount.bankName,
        cardNumber: targetAccount.cardNumber,
        accountHolder: targetAccount.accountHolder
      },
      status: 'applied',
      applyTime: formattedTime,
      financeNote: '已提交财务团队审核，预计 1 个工作日内完成划转打款'
    };

    setWithdrawalRecords([newRecord, ...withdrawalRecords]);
    setWithdrawableBalance(prev => prev - amountNum);
    setShowWithdrawModal(false);
    setSettlementSubTab('withdrawals');
    alert(`提现申请提交成功！金额 ¥${amountNum.toFixed(2)} 已转入【待财务审核】队列。`);
  };

  const handleAddBankAccount = (e: React.FormEvent) => {
    e.preventDefault();
    if (!newBankName || !newCardNumber) {
      alert('请填写完整的银行/收款机构名称及账号');
      return;
    }

    const newAcc: BankAccount = {
      id: `bank_${Date.now()}`,
      accountType: 'bank_card',
      bankName: newBranchName ? `${newBankName} (${newBranchName})` : newBankName,
      cardNumber: newCardNumber,
      accountHolder: newAccountHolder,
      phone: '',
      isDefault: bankAccounts.length === 0
    };

    setBankAccounts([...bankAccounts, newAcc]);
    setNewBankName('');
    setNewBranchName('');
    setNewCardNumber('');
    setNewAccountHolder(consultant.name);
    setShowAddAccountModal(false);
    alert('收款账号添加成功！');
  };

  const filteredBillRecords = billRecords.filter(bill => {
    if (billStatusFilter === 'all') return true;
    return bill.status === billStatusFilter;
  });

  const pendingSettlementTotal = billRecords
    .filter(b => b.status === 'pending_settlement')
    .reduce((sum, b) => sum + b.netAmount, 0);
  const workflowSettlements = Object.entries(workflow.settlements)
    .filter(([, status]) => status === 'blocked_by_summary' || status === 'eligible_t1')
    .map(([orderId, status]) => ({
      order: orders.find((order) => order.id === orderId),
      status,
      draftId: workflow.reviewDrafts.find((draft) => draft.orderId === orderId)?.id,
    }))
    .filter((item) => item.order);

  const renderBillStatusBadge = (status: BillRecordStatus) => {
    switch (status) {
      case 'settled':
        return (
          <span className="bg-[#EADDFF] text-[#21005D] px-2 py-0.5 rounded-full text-[10px] font-semibold border border-[#D0BCFF] inline-flex items-center gap-1">
            <CheckCircle2 className="w-3 h-3 text-[#6750A4]" />
            <span>已入账</span>
          </span>
        );
      case 'pending_settlement':
        return (
          <span className="bg-amber-50 text-amber-800 px-2 py-0.5 rounded-full text-[10px] font-semibold border border-amber-200 inline-flex items-center gap-1">
            <Clock className="w-3 h-3 text-amber-600" />
            <span>待结算</span>
          </span>
        );
      case 'refunded':
        return (
          <span className="bg-stone-100 text-stone-600 px-2 py-0.5 rounded-full text-[10px] font-semibold border border-stone-200 inline-flex items-center gap-1">
            <XCircle className="w-3 h-3 text-stone-500" />
            <span>已退款</span>
          </span>
        );
      default:
        return null;
    }
  };

  const getWithdrawalStatusBadge = (status: WithdrawalRecord['status']) => {
    switch (status) {
      case 'applied':
        return (
          <span className="bg-sky-50 text-sky-800 px-2 py-0.5 rounded-full text-[10px] font-semibold border border-sky-200 inline-flex items-center gap-1">
            <Clock className="w-3 h-3 text-sky-600" />
            <span>用户申请</span>
          </span>
        );
      case 'reviewing':
        return (
          <span className="bg-amber-50 text-amber-800 px-2 py-0.5 rounded-full text-[10px] font-semibold border border-amber-200 inline-flex items-center gap-1">
            <Clock className="w-3 h-3 text-amber-600" />
            <span>平台审核</span>
          </span>
        );
      case 'paying':
        return (
          <span className="bg-blue-50 text-blue-800 px-2 py-0.5 rounded-full text-[10px] font-semibold border border-blue-200 inline-flex items-center gap-1">
            <Wallet className="w-3 h-3 text-blue-600" />
            <span>财务打款</span>
          </span>
        );
      case 'success':
        return (
          <span className="bg-emerald-50 text-emerald-800 px-2 py-0.5 rounded-full text-[10px] font-semibold border border-emerald-200 inline-flex items-center gap-1">
            <CheckCircle2 className="w-3 h-3 text-emerald-600" />
            <span>打款成功</span>
          </span>
        );
      case 'failed':
        return (
          <span className="bg-stone-100 text-stone-600 px-2 py-0.5 rounded-full text-[10px] font-semibold border border-stone-200 inline-flex items-center gap-1">
            <XCircle className="w-3 h-3 text-stone-500" />
            <span>打款失败</span>
          </span>
        );
      default:
        return null;
    }
  };

  return (
    <div className="absolute inset-0 bg-[#FAF8F5] z-50 flex flex-col overflow-hidden sm:rounded-[28px]">
      {/* Header */}
      <div className="flex items-center justify-between px-4 py-3 bg-white border-b border-[#ECE6DC] sticky top-0 z-10 shrink-0 shadow-xs">
        <button
          onClick={onClose}
          className="p-2 -ml-2 rounded-full text-[#49463D] hover:bg-[#F5F2EC] transition flex items-center gap-1 active:scale-95"
        >
          <ArrowLeft className="w-5 h-5" />
          <span className="text-sm font-semibold">返回</span>
        </button>
        <div className="flex flex-col items-center">
          <span className="text-base font-bold text-[#1D1B16]">我的收入与提现</span>
        </div>
        <button
          onClick={() => setShowRulesModal(true)}
          className="p-2 -mr-2 rounded-full text-[#6750A4] hover:bg-[#F5F2EC] transition active:scale-95"
        >
          <Info className="w-5 h-5" />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto scrollbar-none p-4 space-y-4">
        {/* Simplified MVP Balance Hero Box */}
        <div className="bg-white border border-[#E6E0D6] rounded-[28px] p-6 shadow-2xs text-center relative overflow-hidden flex flex-col items-center">
          <div className="absolute top-0 left-1/2 -translate-x-1/2 w-48 h-48 bg-[radial-gradient(ellipse_at_center,_var(--tw-gradient-stops))] from-[#6750A4]/10 to-transparent rounded-full blur-2xl pointer-events-none" />
          
          <div className="relative z-10 w-full flex flex-col items-center">
            <div className="text-xs text-[#7A756C] mb-2 flex items-center gap-1">
              当前可提现余额 (元)
              <span className="text-[10px] bg-[#EADDFF] text-[#21005D] px-1.5 py-0.5 rounded-full font-semibold">T+1</span>
            </div>
            
            <div className="text-4xl font-bold font-mono text-[#1D1B16] mb-6 tracking-tight">
              ¥{withdrawableBalance.toFixed(2)}
            </div>

            <button
              onClick={() => setShowWithdrawModal(true)}
              className="w-full max-w-[240px] py-3.5 rounded-full bg-[#6750A4] text-white text-sm font-bold shadow-xs active:scale-95 flex items-center justify-center gap-2 mb-5 transition-transform"
            >
              <Wallet className="w-4 h-4" />
              <span>发起提现申请</span>
            </button>

            <button
              onClick={() => setShowAccountsView(true)}
              className="w-full bg-[#FAF8F5] border border-[#ECE6DC] p-3 rounded-[20px] flex items-center justify-between active:scale-[0.99] transition-transform"
            >
              <div className="flex items-center gap-2.5">
                <div className="w-8 h-8 rounded-full bg-white border border-[#E6E0D6] flex items-center justify-center shadow-xs shrink-0">
                  <Building2 className="w-4 h-4 text-[#6750A4]" />
                </div>
                <div className="text-left">
                  <div className="text-xs font-bold text-[#1D1B16]">收款账户</div>
                  <div className="text-[10px] text-[#7A756C] mt-0.5">
                    {bankAccounts[0] ? `${bankAccounts[0].bankName} (尾号${bankAccounts[0].cardNumber.slice(-4)})` : '尚未绑定，点击添加'}
                  </div>
                </div>
              </div>
              <ChevronRight className="w-4 h-4 text-[#7A756C]" />
            </button>
          </div>
        </div>



        {/* Sub Navigation Bar */}
        <div className="bg-[#FAF8F5] border border-[#ECE6DC] p-1.5 rounded-[20px] flex items-center gap-1 shadow-2xs text-xs">
          <button
            onClick={() => setSettlementSubTab('bills')}
            className={`flex-1 py-2 px-3 rounded-[14px] font-semibold transition active:scale-95 flex items-center justify-center gap-1.5 ${
              settlementSubTab === 'bills' ? 'bg-[#6750A4] text-white shadow-2xs' : 'text-[#49463D] hover:bg-[#E8E2D5]'
            }`}
          >
            <FileText className="w-4 h-4" />
            <span>入账明细 ({billRecords.length})</span>
          </button>
          <button
            onClick={() => setSettlementSubTab('withdrawals')}
            className={`flex-1 py-2 px-3 rounded-[14px] font-semibold transition active:scale-95 flex items-center justify-center gap-1.5 ${
              settlementSubTab === 'withdrawals' ? 'bg-[#6750A4] text-white shadow-2xs' : 'text-[#49463D] hover:bg-[#E8E2D5]'
            }`}
          >
            <History className="w-4 h-4" />
            <span>提现记录 ({withdrawalRecords.length})</span>
          </button>
        </div>

        {/* SUB TAB 1: BILLS LIST */}
        {settlementSubTab === 'bills' && (
          <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-4 shadow-2xs space-y-3">
            <div className="flex items-center justify-between pb-2 border-b border-[#ECE6DC] flex-wrap gap-2">
              <div className="flex items-center gap-1 overflow-x-auto scrollbar-none text-xs">
                {[
                  { id: 'all', label: '全部' },
                  { id: 'settled', label: '已入账' },
                  { id: 'pending_settlement', label: '待结算' },
                  { id: 'refunded', label: '已退款' },
                ].map((filter) => (
                  <button
                    key={filter.id}
                    onClick={() => setBillStatusFilter(filter.id as any)}
                    className={`px-3 py-1 rounded-full font-semibold transition active:scale-95 ${
                      billStatusFilter === filter.id ? 'bg-[#6750A4] text-white shadow-2xs' : 'bg-[#FAF8F5] text-[#7A756C] border border-[#ECE6DC] hover:text-[#1D1B16]'
                    }`}
                  >
                    {filter.label}
                  </button>
                ))}
              </div>
              <span className="text-[11px] text-[#7A756C]">按 12% 平台费率计算</span>
            </div>

            <div className="space-y-2.5 pt-1">
              {filteredBillRecords.length === 0 ? (
                <div className="text-center py-10 flex flex-col items-center bg-[#FAF8F5] rounded-[18px] border border-[#ECE6DC]">
                  <div className="w-12 h-12 bg-white rounded-full flex items-center justify-center mb-2 shadow-sm border border-[#E6E0D6]">
                    <FileText className="w-5 h-5 text-[#A09C94]" />
                  </div>
                  <p className="text-[13px] font-bold text-[#1D1B16] mb-0.5">暂无账单记录</p>
                  <p className="text-[11px] text-[#7A756C]">当有咨询订单完成并结算后，这里会产生账单</p>
                </div>
              ) : (
                filteredBillRecords.map((bill) => (
                  <div 
                    key={bill.id} 
                    onClick={() => {
                      if (onOpenOrderInfo && bill.orderId) {
                        const order = orders.find(o => o.id === bill.orderId);
                        if (order) onOpenOrderInfo(order);
                      }
                    }}
                    className="bg-[#FAF8F5] p-3.5 rounded-[18px] border border-[#ECE6DC] hover:border-[#D0BCFF] transition space-y-2.5 cursor-pointer active:scale-[0.99]"
                  >
                    <div className="flex items-center justify-between text-xs pb-2 border-b border-[#ECE6DC]">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-[11px] font-bold text-[#1D1B16]">{bill.billNo}</span>
                      </div>
                      {renderBillStatusBadge(bill.status)}
                    </div>
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <div className="font-bold text-xs text-[#1D1B16] flex items-center gap-2">
                          <span>{bill.clientName}</span>
                          <span className="text-[11px] text-[#49463D] font-normal">{bill.serviceTypeName}</span>
                        </div>
                        <div className="text-[11px] text-[#7A756C] mt-0.5 font-mono">
                          预约时间: {bill.bookingDate} {bill.bookingTimeSlot || ''}
                        </div>
                      </div>
                      <div className="text-right shrink-0">
                        <div className="text-base font-bold font-mono text-[#6750A4]">+¥{bill.netAmount.toFixed(2)}</div>
                        <div className="text-[10px] text-[#7A756C] font-mono mt-0.5">原价¥{bill.grossAmount} (扣12%)</div>
                      </div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        )}

        {/* SUB TAB 2: WITHDRAWAL RECORDS */}
        {settlementSubTab === 'withdrawals' && (
          <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-4 shadow-2xs space-y-3">
            <div className="space-y-2.5">
              {withdrawalRecords.length === 0 ? (
                <div className="text-center py-10 flex flex-col items-center bg-[#FAF8F5] rounded-[18px] border border-[#ECE6DC]">
                  <div className="w-12 h-12 bg-white rounded-full flex items-center justify-center mb-2 shadow-sm border border-[#E6E0D6]">
                    <History className="w-5 h-5 text-[#A09C94]" />
                  </div>
                  <p className="text-[13px] font-bold text-[#1D1B16] mb-0.5">暂无提现记录</p>
                  <p className="text-[11px] text-[#7A756C]">您还没有发起过提现申请</p>
                </div>
              ) : (
                withdrawalRecords.map((record) => (
                  <div 
                    key={record.id} 
                    onClick={() => setActiveWithdrawalDetail(record)}
                    className="bg-[#FAF8F5] p-3.5 rounded-[18px] border border-[#ECE6DC] space-y-2.5 cursor-pointer hover:border-[#D0BCFF] transition active:scale-[0.99]"
                  >
                    <div className="flex items-center justify-between text-xs pb-2 border-b border-[#ECE6DC]">
                      <span className="font-mono text-[11px] font-bold text-[#1D1B16]">{record.withdrawNo}</span>
                      {getWithdrawalStatusBadge(record.status)}
                    </div>
                    <div className="flex justify-between items-center">
                      <div>
                        <div className="text-xs font-bold text-[#1D1B16]">{record.bankAccount.bankName}</div>
                        <div className="text-[10px] text-[#7A756C] font-mono mt-0.5">尾号: {record.bankAccount.cardNumber.slice(-4)}</div>
                      </div>
                      <div className="text-base font-bold font-mono text-[#1D1B16]">-¥{record.amount.toFixed(2)}</div>
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        )}


      </div>

      {/* Add Bank Account Modal */}
      {showAddAccountModal && (
        <div className="fixed inset-0 z-[80] bg-black/40 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4 animate-in fade-in">
          <div className="bg-[#FAF8F5] border border-[#E6E0D6] rounded-t-[28px] sm:rounded-[28px] max-w-md w-full p-5 shadow-2xl relative">
            <button onClick={() => setShowAddAccountModal(false)} className="absolute top-4 right-4 p-1.5 rounded-full text-[#7A756C] hover:bg-[#E8E2D5]">
              <X className="w-5 h-5" />
            </button>
            <h3 className="font-bold text-base text-[#1D1B16] mb-4">添加收款账号</h3>
            <form onSubmit={handleAddBankAccount} className="space-y-4 text-xs">
              <div>
                <label className="block text-[#1D1B16] font-semibold mb-1">开户银行名称</label>
                <input required value={newBankName} onChange={(e) => setNewBankName(e.target.value)} className="w-full bg-white border border-[#E6E0D6] rounded-full px-3.5 py-2 text-[#1D1B16]" placeholder="例如：招商银行" />
              </div>
              <div>
                <label className="block text-[#1D1B16] font-semibold mb-1">开户支行</label>
                <input required value={newBranchName} onChange={(e) => setNewBranchName(e.target.value)} className="w-full bg-white border border-[#E6E0D6] rounded-full px-3.5 py-2 text-[#1D1B16]" placeholder="例如：上海静安支行" />
              </div>
              <div>
                <label className="block text-[#1D1B16] font-semibold mb-1">收款卡号</label>
                <input required value={newCardNumber} onChange={(e) => setNewCardNumber(e.target.value)} className="w-full bg-white border border-[#E6E0D6] rounded-full px-3.5 py-2 text-[#1D1B16] font-mono" placeholder="输入银行卡号" />
              </div>
              <div>
                <label className="block text-[#1D1B16] font-semibold mb-1">持卡人姓名</label>
                <input required value={newAccountHolder} onChange={(e) => setNewAccountHolder(e.target.value)} className="w-full bg-white border border-[#E6E0D6] rounded-full px-3.5 py-2 text-[#1D1B16]" placeholder="输入持卡人姓名" />
              </div>
              <button type="submit" className="w-full py-3 rounded-full bg-[#6750A4] text-white text-sm font-bold shadow-xs active:scale-95">确认添加并绑定</button>
            </form>
          </div>
        </div>
      )}

      {/* Withdraw Modal */}
      {showWithdrawModal && (
        <div className="fixed inset-0 z-[60] bg-black/40 backdrop-blur-xs flex items-end sm:items-center justify-center p-0 sm:p-4 animate-in fade-in">
          <div className="bg-[#FAF8F5] border border-[#E6E0D6] rounded-t-[28px] sm:rounded-[28px] max-w-md w-full p-5 shadow-2xl relative">
            <button onClick={() => setShowWithdrawModal(false)} className="absolute top-4 right-4 p-1.5 rounded-full text-[#7A756C] hover:bg-[#E8E2D5]">
              <X className="w-5 h-5" />
            </button>
            <h3 className="font-bold text-base text-[#1D1B16] mb-4 flex items-center gap-2"><Wallet className="w-5 h-5 text-[#6750A4]" />发起余额提现</h3>
            <form onSubmit={handleApplyWithdraw} className="space-y-4">
              <div className="bg-white border border-[#E6E0D6] p-3 rounded-[16px]">
                <label className="block text-[11px] text-[#7A756C] mb-1">选择到账账户</label>
                <select value={selectedAccountId} onChange={(e) => setSelectedAccountId(e.target.value)} className="w-full bg-transparent text-xs font-bold text-[#1D1B16] focus:outline-hidden">
                  {bankAccounts.map(a => <option key={a.id} value={a.id}>{a.bankName} (尾号{a.cardNumber.slice(-4)})</option>)}
                </select>
              </div>
              <div className="bg-white border border-[#E6E0D6] p-4 rounded-[20px]">
                <label className="block text-[11px] text-[#7A756C] mb-2">提现金额 (¥)</label>
                <div className="flex items-center gap-2 border-b-2 border-[#E6E0D6] pb-2 focus-within:border-[#6750A4] transition-colors">
                  <span className="text-2xl font-bold text-[#1D1B16]">¥</span>
                  <input type="number" min="100" max={withdrawableBalance} step="0.01" required value={withdrawAmountInput} onChange={(e) => setWithdrawAmountInput(e.target.value)} className="w-full bg-transparent text-3xl font-bold font-mono text-[#6750A4] focus:outline-hidden placeholder-[#ECE6DC]" />
                </div>
                <div className="flex items-center justify-between mt-2 text-[10px]">
                  <span className="text-[#7A756C]">可提现余额: ¥{withdrawableBalance.toFixed(2)}</span>
                  <button type="button" onClick={() => setWithdrawAmountInput(withdrawableBalance.toString())} className="text-[#6750A4] font-bold hover:underline">全部提现</button>
                </div>
              </div>
              <button type="submit" className="w-full py-3.5 rounded-full bg-[#6750A4] text-white text-sm font-bold shadow-xs active:scale-95 flex justify-center items-center gap-2">
                <Check className="w-4 h-4" /> 确认提交审核
              </button>
            </form>
          </div>
        </div>
      )}

      {/* Rules Modal */}
      {showRulesModal && (
        <div className="fixed inset-0 z-[60] bg-black/40 backdrop-blur-xs flex items-center justify-center p-4 animate-in fade-in">
          <div className="bg-white border border-[#E6E0D6] rounded-[28px] max-w-md w-full p-6 shadow-2xl relative space-y-4 text-xs text-[#1D1B16]">
            <button onClick={() => setShowRulesModal(false)} className="absolute top-4 right-4 p-2 rounded-full text-[#7A756C] hover:text-[#1D1B16] hover:bg-[#E8E2D5]">
              <X className="w-5 h-5" />
            </button>
            <div className="flex items-center gap-2 text-base font-bold text-[#6750A4]">
              <Info className="w-5 h-5 text-[#6750A4]" /><span>咨询师提现规则与结算约定</span>
            </div>
            <div className="space-y-3 bg-[#FAF8F5] p-4 rounded-[20px] border border-[#ECE6DC] leading-relaxed text-[#49463D]">
              <div><strong className="text-[#1D1B16] block mb-0.5">1. 入账条件与时效约定</strong><p>当咨询师完成咨询服务，且成功提交相应的【咨询小结】及必填记录后，系统将于次日（T+1）自动将该笔订单的实际应得收益划入【可提现余额】。</p></div>
              <div><strong className="text-[#1D1B16] block mb-0.5">2. 提现额度与手续费</strong><p>单笔提现申请最低额度为 <span className="font-bold text-[#6750A4]">¥100.00</span>。由于涉及分账和个人扣税，平台全额补贴提现渠道手续费。</p></div>
              <div><strong className="text-[#1D1B16] block mb-0.5">3. 提现审核与打款周期</strong><p>提交提现申请后，将先由平台运营团队进行服务复核，审核通过后提交财务进行人工或第三方渠道打款。整体流程预计 <span className="font-bold text-[#A23F1E]">3-7 个工作日</span> 内完成到账。</p></div>
              <div><strong className="text-[#1D1B16] block mb-0.5">4. 实名一致性合规</strong><p>提现收款卡开户人姓名必须与咨询师 CPS 执业认证实名姓名（{consultant.name}）完全相符，严禁代领。</p></div>
            </div>
            <div className="flex justify-end pt-1">
              <button onClick={() => setShowRulesModal(false)} className="px-6 py-2 bg-[#6750A4] text-white rounded-full font-semibold hover:bg-[#594294] shadow-2xs">我已了解</button>
            </div>
          </div>
        </div>
      )}

      {/* Withdrawal Detail Full Page View */}
      {activeWithdrawalDetail && (
        <div className="fixed inset-0 z-[70] bg-[#FAF8F5] overflow-y-auto animate-in fade-in flex flex-col">
          <div className="flex items-center justify-between px-4 py-3 bg-white border-b border-[#ECE6DC] sticky top-0 z-10 shrink-0 shadow-xs">
            <button
              onClick={() => setActiveWithdrawalDetail(null)}
              className="p-2 -ml-2 rounded-full text-[#49463D] hover:bg-[#F5F2EC] transition flex items-center gap-1 active:scale-95"
            >
              <ArrowLeft className="w-5 h-5" />
              <span className="text-sm font-semibold">返回</span>
            </button>
            <div className="flex flex-col items-center">
              <span className="text-base font-bold text-[#1D1B16]">提现详情</span>
            </div>
            <div className="w-9" />
          </div>

          <div className="p-4 space-y-4">
            <div className="bg-white border border-[#E6E0D6] rounded-[24px] p-6 shadow-2xs">
              <div className="text-center pb-6 border-b border-[#ECE6DC] mb-6">
                <div className="text-sm font-bold text-[#7A756C] mb-2">提现金额</div>
                <div className="text-4xl font-mono font-bold text-[#1D1B16]">-¥{activeWithdrawalDetail.amount.toFixed(2)}</div>
                <div className="mt-4 inline-flex">
                  {getWithdrawalStatusBadge(activeWithdrawalDetail.status)}
                </div>
              </div>
              <div className="space-y-5 text-sm">
                <div className="flex justify-between items-start">
                  <span className="text-[#7A756C]">提现单号</span>
                  <span className="font-mono text-[#1D1B16] font-medium text-right">{activeWithdrawalDetail.withdrawNo}</span>
                </div>
                <div className="flex justify-between items-start">
                  <span className="text-[#7A756C]">申请时间</span>
                  <span className="font-mono text-[#1D1B16] font-medium text-right">{activeWithdrawalDetail.applyTime}</span>
                </div>
                {activeWithdrawalDetail.completedTime && (
                  <div className="flex justify-between items-start">
                    <span className="text-[#7A756C]">到账时间</span>
                    <span className="font-mono text-[#1D1B16] font-medium text-right">{activeWithdrawalDetail.completedTime}</span>
                  </div>
                )}
                <div className="flex justify-between items-start">
                  <span className="text-[#7A756C]">收款账户</span>
                  <div className="text-right">
                    <div className="text-[#1D1B16] font-medium">{activeWithdrawalDetail.bankAccount.bankName}</div>
                    <div className="font-mono text-[#7A756C] mt-0.5">**** {activeWithdrawalDetail.bankAccount.cardNumber.slice(-4)}</div>
                  </div>
                </div>
                <div className="flex justify-between items-start">
                  <span className="text-[#7A756C]">手续费</span>
                  <span className="text-[#1D1B16] font-medium text-right">¥0.00 (平台全额补贴)</span>
                </div>
                {activeWithdrawalDetail.financeNote && (
                  <div className="mt-4 p-4 bg-[#FAF8F5] rounded-[16px] border border-[#ECE6DC]">
                    <div className="text-[#7A756C] mb-1.5 text-xs font-bold">进度与备注</div>
                    <div className="text-[#1D1B16] leading-relaxed text-xs">{activeWithdrawalDetail.financeNote}</div>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Accounts Management Full Page View */}
      {showAccountsView && (
        <div className="fixed inset-0 z-[70] bg-[#FAF8F5] overflow-y-auto animate-in fade-in flex flex-col">
          <div className="flex items-center justify-between px-4 py-3 bg-white border-b border-[#ECE6DC] sticky top-0 z-10 shrink-0 shadow-xs">
            <button
              onClick={() => setShowAccountsView(false)}
              className="p-2 -ml-2 rounded-full text-[#49463D] hover:bg-[#F5F2EC] transition flex items-center gap-1 active:scale-95"
            >
              <ArrowLeft className="w-5 h-5" />
              <span className="text-sm font-semibold">返回</span>
            </button>
            <div className="flex flex-col items-center">
              <span className="text-base font-bold text-[#1D1B16]">收款账户管理</span>
            </div>
            <div className="w-9" />
          </div>

          <div className="p-4 space-y-4">
            <button
              onClick={() => setShowAddAccountModal(true)}
              className="w-full py-4 rounded-[20px] border-2 border-dashed border-[#ECE6DC] bg-white text-[#7A756C] hover:border-[#6750A4] hover:text-[#6750A4] hover:bg-[#F5F2EC] transition flex flex-col items-center justify-center gap-2 active:scale-[0.98]"
            >
              <div className="w-10 h-10 rounded-full bg-[#FAF8F5] flex items-center justify-center border border-[#ECE6DC]">
                <Plus className="w-5 h-5" />
              </div>
              <span className="text-sm font-bold">添加新的收款账号</span>
            </button>
            
            <div className="space-y-3">
              {bankAccounts.map((acc) => (
                <div key={acc.id} className="bg-white p-5 rounded-[24px] border border-[#ECE6DC] shadow-2xs relative">
                  {acc.isDefault && <span className="absolute top-5 right-5 bg-[#EADDFF] text-[#21005D] border border-[#D0BCFF] text-[10px] px-2 py-0.5 rounded-full font-bold">默认收款</span>}
                  <div className="flex items-center gap-4 mb-4">
                    <div className="w-12 h-12 rounded-full bg-[#FAF8F5] border border-[#E6E0D6] flex items-center justify-center">
                      <Building2 className="w-6 h-6 text-[#6750A4]" />
                    </div>
                    <div>
                      <div className="font-bold text-base text-[#1D1B16]">{acc.bankName}</div>
                      <div className="text-sm text-[#7A756C] font-mono tracking-widest mt-1">**** **** **** {acc.cardNumber.slice(-4)}</div>
                    </div>
                  </div>
                  <div className="flex items-center gap-4 text-xs text-[#49463D] bg-[#FAF8F5] p-3 rounded-[16px] border border-[#ECE6DC]">
                    <div className="flex items-center gap-1.5"><User className="w-4 h-4 text-[#7A756C]" /> 持卡人：{acc.accountHolder}</div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

    </div>
  );
};
