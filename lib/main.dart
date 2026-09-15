import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
void main() {
  runApp(const InstallmentApp());
}

class InstallmentApp extends StatelessWidget {
  const InstallmentApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منظومة إدارة التقسيط والحسابات',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'sans-serif',
        primaryColor: const Color(0xFF0F172A),
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 2; // فتح لوحة التحكم
  final GlobalKey<_CustomersScreenState> _customersKey = GlobalKey<_CustomersScreenState>();
  final GlobalKey<_DashboardScreenState> _dashboardKey = GlobalKey<_DashboardScreenState>();

  void _navigateToCustomersTab() {
    setState(() {
      _currentIndex = 0;
    });
    _customersKey.currentState?.fetchCustomers();
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      CustomersScreen(key: _customersKey),
      ContractCalculatorScreen(onContractCreated: _navigateToCustomersTab),
      DashboardScreen(key: _dashboardKey),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            if (index == 0) {
              _customersKey.currentState?.fetchCustomers();
            } else if (index == 2) {
              _dashboardKey.currentState?.fetchDashboardStats();
            }
          },
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0F172A),
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.people_alt_outlined),
              activeIcon: Icon(Icons.people_alt),
              label: 'العملاء والتحصيل',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calculate_outlined),
              activeIcon: Icon(Icons.calculate),
              label: 'عقد جديد وحاسبة',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'لوحة التحكم',
            ),
          ],
        ),
      ),
    );
  }
}

// دالة تنسيق الأرقام بدون كسور لا نهائية
String formatMoney(dynamic val) {
  if (val == null) return "0 ج.م";
  final num numVal = (val is num) ? val : (double.tryParse(val.toString()) ?? 0.0);
  return "${numVal.toStringAsFixed(1).replaceAll('.0', '')} ج.م";
}

// -----------------------------------------------------------------------------
// الشاشة 1: لوحة التحكم (تمت إزالة الخطوط الصفراء والسوداء والأخطاء تماماً)
// -----------------------------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    fetchDashboardStats();
  }

  Future<void> fetchDashboardStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await http.get(Uri.parse('https://installment-system-production.up.railway.app/dashboard/stats/')).timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        setState(() {
          _stats = jsonDecode(utf8.decode(res.bodyBytes));
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'فشل جلب الإحصائيات (كود ${res.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'خطأ في الاتصال بالخادم: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'لوحة التحكم والتحليل المالي',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF0F172A),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'تحديث المؤشرات',
            onPressed: fetchDashboardStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 14),
                      ElevatedButton.icon(
                        onPressed: fetchDashboardStats,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
                      )
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // كارت الهيرو العلوي
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('معدل كفاءة التحصيل الكلي', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              Text(
                                '${_stats!['collection_rate']}%',
                                style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 22),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: ((_stats!['collection_rate'] as num?)?.toDouble() ?? 0.0) / 100.0,
                              minHeight: 10,
                              backgroundColor: Colors.white12,
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: _buildHeroStat('إجمالي المحفظة', formatMoney(_stats!['total_portfolio_value']))),
                              Expanded(child: _buildHeroStat('السيولة المحصلة', formatMoney(_stats!['total_collected']))),
                              Expanded(child: _buildHeroStat('المديونية المتبقية', formatMoney(_stats!['total_remaining_debt']))),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // الكروت المالية الأربعة مع منع التداخل
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'المستهدف هذا الشهر',
                            formatMoney(_stats!['current_month_target']),
                            'محصل: ${formatMoney(_stats!['current_month_collected'])}',
                            Icons.monetization_on_outlined,
                            const Color(0xFF059669),
                            const Color(0xFFECFDF5),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            'الأقساط المتأخرة',
                            formatMoney(_stats!['total_overdue_amount']),
                            '${_stats!['total_overdue_installments']} قسط متأخر',
                            Icons.warning_amber_rounded,
                            const Color(0xFFDC2626),
                            const Color(0xFFFEF2F2),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            'إجمالي العملاء',
                            '${_stats!['total_customers_count']} عميل',
                            'مسجل بالمنظومة',
                            Icons.people_outline,
                            const Color(0xFF2563EB),
                            const Color(0xFFEFF6FF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildMetricCard(
                            'العقود النشطة',
                            '${_stats!['total_contracts_count']} عقد',
                            'عقود تقسيط جارية',
                            Icons.receipt_long_outlined,
                            const Color(0xFF7C3AED),
                            const Color(0xFFF5F3FF),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // جدول المتأخرين
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                                  SizedBox(width: 6),
                                  Text(
                                    'أبرز المتأخرين في السداد',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                              Text(
                                '${(_stats!['overdue_customers'] as List).length} عميل',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          if ((_stats!['overdue_customers'] as List).isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Center(
                                child: Text('ممتاز! لا توجد أقساط متأخرة حالياً ✓', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                              ),
                            )
                          else
                            ...(_stats!['overdue_customers'] as List).map((od) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFECACA)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            od['customer_name'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'هاتف: ${od['phone']} (${od['count']} قسط متأخر)',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      formatMoney(od['amount']),
                                      style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // أحدث العقود
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.history, color: Color(0xFF0F172A), size: 20),
                              SizedBox(width: 6),
                              Text(
                                'أحدث العقود المسجلة',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                            ],
                          ),
                          const Divider(height: 18),
                          if ((_stats!['recent_contracts'] as List).isEmpty)
                            const Center(child: Text('لا توجد عقود مسجلة بعد', style: TextStyle(color: Color(0xFF94A3B8))))
                          else
                            ...(_stats!['recent_contracts'] as List).map((rc) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${rc['customer_name']} - ${rc['product_name']}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text('عقد: ${rc['contract_number']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${formatMoney(rc['monthly_installment'])} / شهر',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669), fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
    );
  }

  Widget _buildHeroStat(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(val, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, String sub, IconData icon, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// الشاشة 2: عقد جديد وحاسبة الأقساط
// -----------------------------------------------------------------------------
class ContractCalculatorScreen extends StatefulWidget {
  final VoidCallback onContractCreated;

  const ContractCalculatorScreen({super.key, required this.onContractCreated});

  @override
  State<ContractCalculatorScreen> createState() => _ContractCalculatorScreenState();
}

class _ContractCalculatorScreenState extends State<ContractCalculatorScreen> {
  final _formKey = GlobalKey<FormState>();

  List<dynamic> _existingCustomers = [];
  String? _selectedCustomerId;

  final _nameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _productNameController = TextEditingController(text: "آيفون 16 برو ماكس");

  final _priceController = TextEditingController(text: "52250");
  final _downPaymentController = TextEditingController(text: "5000");
  final _interestRateController = TextEditingController(text: "18.5");

  int _selectedMonths = 12;
  DateTime _firstInstallmentDate = DateTime.now();
  bool _isSubmitting = false;

  double get totalPrice => double.tryParse(_priceController.text) ?? 0.0;
  double get downPayment => double.tryParse(_downPaymentController.text) ?? 0.0;
  double get interestRate => double.tryParse(_interestRateController.text) ?? 0.0;

  double get financedAmount => (totalPrice - downPayment) > 0 ? (totalPrice - downPayment) : 0.0;
  double get totalInterest => financedAmount * (interestRate / 100) * (_selectedMonths / 12);
  double get totalContractAmount => financedAmount + totalInterest;
  double get monthlyInstallment => _selectedMonths > 0 ? (totalContractAmount / _selectedMonths) : 0.0;

  @override
  void initState() {
    super.initState();
    _fetchExistingCustomers();
  }

  Future<void> _fetchExistingCustomers() async {
    try {
      final res = await http.get(Uri.parse('https://installment-system-production.up.railway.app/customers/'));
      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() {
          _existingCustomers = data;
        });
      }
    } catch (_) {}
  }

  void _onCustomerSelected(String? customerId) {
    setState(() {
      _selectedCustomerId = customerId;
      if (customerId == null) {
        _nameController.clear();
        _nationalIdController.clear();
        _phoneController.clear();
      } else {
        final client = _existingCustomers.firstWhere((c) => c['id'] == customerId);
        _nameController.text = client['full_name'] ?? '';
        _nationalIdController.text = client['national_id'] ?? '';
        _phoneController.text = client['phone_number'] ?? '';
      }
    });
  }

  Future<void> _pickFirstInstallmentDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstInstallmentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
    if (picked != null) {
      setState(() {
        _firstInstallmentDate = picked;
      });
    }
  }

  Future<void> _submitContract() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      String finalCustomerId;

      if (_selectedCustomerId == null) {
        final customerBody = jsonEncode({
          "full_name": _nameController.text.trim(),
          "national_id": _nationalIdController.text.trim(),
          "phone_number": _phoneController.text.trim(),
          "address": "القاهرة",
          "monthly_income": 15000.0,
          "credit_limit": 100000.0
        });

        final custRes = await http.post(
          Uri.parse('https://installment-system-production.up.railway.app/customers/'),
          headers: {"Content-Type": "application/json", "bypass-tunnel-reminder": "true"},
          body: customerBody,
        ).timeout(const Duration(seconds: 5));

        if (custRes.statusCode != 200) {
          throw Exception("فشل حفظ بيانات العميل");
        }

        final custData = jsonDecode(utf8.decode(custRes.bodyBytes));
        finalCustomerId = custData['id'];
      } else {
        finalCustomerId = _selectedCustomerId!;
      }

      final contractNumber = "CNT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

      final contractBody = jsonEncode({
        "customer_id": finalCustomerId,
        "contract_number": contractNumber,
        "product_name": _productNameController.text.trim(),
        "total_cash_price": totalPrice,
        "down_payment": downPayment,
        "interest_rate_percent": interestRate,
        "months_count": _selectedMonths,
        "start_date": _firstInstallmentDate.toIso8601String().split('T')[0]
      });

      final contractRes = await http.post(
        Uri.parse('https://installment-system-production.up.railway.app/contracts/'),
        headers: {
  "Content-Type": "application/json",
  "bypass-tunnel-reminder": "true",
},
        body: contractBody,
      ).timeout(const Duration(seconds: 5));

      if (contractRes.statusCode != 200) {
        throw Exception("فشل إصدار العقد");
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✓ تم إصدار عقد (${_productNameController.text.trim()}) بنجاح!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );

      _fetchExistingCustomers();
      widget.onContractCreated();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تنبيه: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isExistingCustomer = _selectedCustomerId != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'منظومة إدارة التقسيط والحسابات',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        centerTitle: true,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('قيمة القسط الشهري المستحق', style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    formatMoney(monthlyInstallment),
                    style: const TextStyle(color: Color(0xFF34D399), fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem('المبلغ الممول', formatMoney(financedAmount)),
                      _buildSummaryItem('إجمالي الفائدة', formatMoney(totalInterest)),
                      _buildSummaryItem('إجمالي العقد', formatMoney(totalContractAmount)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('اختيار العميل وبيانات العقد', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedCustomerId,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Row(
                              children: [
                                Icon(Icons.person_add_alt_1, color: Color(0xFF059669), size: 18),
                                SizedBox(width: 8),
                                Text('+ إضافة عميل جديد', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                              ],
                            ),
                          ),
                          ..._existingCustomers.map((c) {
                            return DropdownMenuItem<String?>(
                              value: c['id'].toString(),
                              child: Text('${c['full_name']} (${c['phone_number']})'),
                            );
                          }).toList(),
                        ],
                        onChanged: _onCustomerSelected,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    enabled: !isExistingCustomer,
                    decoration: InputDecoration(
                      labelText: isExistingCustomer ? 'اسم العميل (مسجل مسبقاً)' : 'اسم العميل بالكامل',
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF64748B)),
                      filled: isExistingCustomer,
                      fillColor: isExistingCustomer ? const Color(0xFFF1F5F9) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'اسم العميل مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nationalIdController,
                    enabled: !isExistingCustomer,
                    decoration: InputDecoration(
                      labelText: 'الرقم القومي (14 رقم)',
                      prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF64748B)),
                      filled: isExistingCustomer,
                      fillColor: isExistingCustomer ? const Color(0xFFF1F5F9) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (val) => val != null && val.length == 14 ? null : '14 رقم مطلوب',
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phoneController,
                    enabled: !isExistingCustomer,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'رقم الهاتف',
                      prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF64748B)),
                      filled: isExistingCustomer,
                      fillColor: isExistingCustomer ? const Color(0xFFF1F5F9) : Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'رقم الهاتف مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _productNameController,
                    decoration: InputDecoration(
                      labelText: 'اسم السلعة / المنتج المقسط',
                      prefixIcon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF64748B)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'اسم السلعة مطلوب' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'إجمالي قيمة البيع (ج.م)',
                      prefixText: 'ج.م ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _downPaymentController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'المقدم المدفوع (ج.م)',
                      prefixText: 'ج.م ',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _interestRateController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'النسبة المئوية السنوية للفائدة (%)',
                      suffixText: '% سنوي',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickFirstInstallmentDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Color(0xFF0F172A), size: 20),
                          const SizedBox(width: 10),
                          const Text(
                            'تاريخ أول قسط:',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                          const Spacer(),
                          Text(
                            '${_firstInstallmentDate.year}-${_firstInstallmentDate.month.toString().padLeft(2, '0')}-${_firstInstallmentDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('مدة التقسيط:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [3, 6, 12, 18, 24].map((m) {
                        final isSelected = _selectedMonths == m;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: ChoiceChip(
                            label: Text('$m شهر'),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0F172A),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) {
                              if (val) setState(() => _selectedMonths = m);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitContract,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline, color: Colors.white),
                label: Text(
                  _isSubmitting ? 'جاري تسجيل العقد والجدولة...' : 'إصدار العقد وتوليد جدول الأقساط',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// الشاشة 3: العملاء والتحصيل
// -----------------------------------------------------------------------------
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  List<dynamic> customers = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http
    .get(
      Uri.parse('https://installment-system-production.up.railway.app/customers/'),
      headers: {
        "bypass-tunnel-reminder": "true",
      },
    )
    .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          customers = data;
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'فشل جلب العملاء: كود ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'خطأ في الاتصال بالخادم: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _deleteCustomer(String customerId, String customerName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('تأكيد مسح العميل'),
            ],
          ),
          content: Text('هل أنت متأكد من مسح العميل ($customerName)؟ سيتم حذف جميع عقوده وأقساطه نهائياً.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('مسح نهائي', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      final res = await http.delete(Uri.parse('https://installment-system-production.up.railway.app/customers/$customerId/'));
      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ تم مسح العميل ($customerName) بنجاح'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        fetchCustomers();
      } else {
        throw Exception('فشل حذف العميل');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء المسح: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'العملاء والتحصيل',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'تحديث البيانات',
            onPressed: fetchCustomers,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: fetchCustomers,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F172A)),
                      )
                    ],
                  ),
                )
              : customers.isEmpty
                  ? const Center(
                      child: Text('لا يوجد عملاء مسجلين حتى الآن.'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        final contracts = (customer['contracts'] as List<dynamic>?) ?? [];
                        final monthlySchedule = (customer['monthly_schedule'] as List<dynamic>?) ?? [];
                        
                        final double totalDebt = (customer['total_debt'] as num?)?.toDouble() ?? 0.0;
                        final double totalMonthlySum = (customer['total_monthly_sum'] as num?)?.toDouble() ?? 0.0;
                        final int remainingMonths = customer['total_remaining_months'] ?? 0;
                        final bool hasOverdue = customer['has_overdue'] ?? false;
                        final int overdueCount = customer['total_overdue_count'] ?? 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: hasOverdue ? const Color(0xFFF87171) : const Color(0xFFE2E8F0),
                              width: hasOverdue ? 1.5 : 1.0,
                            ),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () async {
                              final needRefresh = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CustomerMonthlyScheduleScreen(
                                    customer: customer,
                                    contracts: contracts,
                                    monthlySchedule: monthlySchedule,
                                  ),
                                ),
                              );
                              if (needRefresh == true) {
                                fetchCustomers();
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: hasOverdue ? const Color(0xFFDC2626) : const Color(0xFF0F172A),
                                            radius: 22,
                                            child: Text(
                                              (customer['full_name'] as String).isNotEmpty
                                                  ? (customer['full_name'] as String)[0]
                                                  : 'ع',
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                customer['full_name'] ?? 'بدون اسم',
                                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                              ),
                                              Text(
                                                'هاتف: ${customer['phone_number'] ?? '-'}',
                                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFECFDF5),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: const Color(0xFFA7F3D0)),
                                            ),
                                            child: Text(
                                              '${customer['contracts_count']} عقود',
                                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert, color: Color(0xFF64748B)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            onSelected: (val) {
                                              if (val == 'delete') {
                                                _deleteCustomer(customer['id'], customer['full_name'] ?? '');
                                              }
                                            },
                                            itemBuilder: (ctx) => [
                                              const PopupMenuItem<String>(
                                                value: 'delete',
                                                child: Row(
                                                  children: [
                                                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                                    SizedBox(width: 8),
                                                    Text('مسح العميل', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (hasOverdue) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF2F2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFFCA5A5)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            'متأخر في سداد ($overdueCount) شهر عن الميعاد المحدد',
                                            style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                  const Divider(height: 22),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE2E8F0)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildStatColumn('إجمالي المديونية', formatMoney(totalDebt), const Color(0xFFDC2626)),
                                        _buildStatColumn('إجمالي قسط الشهر', formatMoney(totalMonthlySum), const Color(0xFF0F172A)),
                                        _buildStatColumn('المتبقي لانتهاء الأقساط', '$remainingMonths شهر', const Color(0xFF2563EB)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: const [
                                      Text('اضغط لإدارة سداد الشهور والمزيد', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      SizedBox(width: 4),
                                      Icon(Icons.arrow_back_ios_new, size: 11, color: Color(0xFF64748B)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildStatColumn(String label, String val, Color valColor) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valColor)),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// الشاشة 4: جدول سداد الأقساط + زر فتح صفحة المنتجات المستقلة
// -----------------------------------------------------------------------------
class CustomerMonthlyScheduleScreen extends StatefulWidget {
  final dynamic customer;
  final List<dynamic> contracts;
  final List<dynamic> monthlySchedule;

  const CustomerMonthlyScheduleScreen({
    super.key,
    required this.customer,
    required this.contracts,
    required this.monthlySchedule,
  });

  @override
  State<CustomerMonthlyScheduleScreen> createState() => _CustomerMonthlyScheduleScreenState();
}

class _CustomerMonthlyScheduleScreenState extends State<CustomerMonthlyScheduleScreen> {
  late List<dynamic> _months;
  late List<dynamic> _contracts;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _months = widget.monthlySchedule;
    _contracts = widget.contracts;
  }

  Future<void> _payFullMonth(int monthIndex, List<dynamic> scheduleIds) async {
    try {
      final res = await http.post(
        Uri.parse('https://installment-system-production.up.railway.app/installments/pay-month/'),
        headers: {"Content-Type": "application/json", "bypass-tunnel-reminder": "true"},
        body: jsonEncode({"schedule_ids": scheduleIds}),
      );

      if (res.statusCode == 200) {
        setState(() {
          _months[monthIndex]['is_paid'] = true;
          _months[monthIndex]['is_overdue'] = false;
          _changed = true;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ تم تسجيل سداد قسط الشهر بنجاح!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception("فشل عملية السداد");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تنبيه: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _changed);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'جدول سداد أقساط: ${widget.customer['full_name']}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF0F172A),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context, _changed),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('إجمالي القسط الشهري المستحق', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            '${formatMoney(widget.customer['total_monthly_sum'])} / شهر',
                            style: const TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_contracts.length} عقود نشطة',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white12, height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final updated = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerProductsScreen(
                              customerName: widget.customer['full_name'] ?? '',
                              contracts: _contracts,
                            ),
                          ),
                        );
                        if (updated == true) {
                          _changed = true;
                          Navigator.pop(context, true);
                        }
                      },
                      icon: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 18),
                      label: const Text(
                        'عرض بطاقات المنتجات والعقود (صفحة مستقلة)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E293B),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: const BorderSide(color: Color(0xFF334155)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'الجدول الشهري للأقساط:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 10),

            ..._months.asMap().entries.map((entry) {
              final idx = entry.key;
              final m = entry.value;
              final bool isPaid = m['is_paid'] == true;
              final bool isOverdue = m['is_overdue'] == true;
              final double totalDue = (m['total_due'] as num?)?.toDouble() ?? 0.0;
              final List<dynamic> scheduleIds = (m['schedule_ids'] as List<dynamic>?) ?? [];

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isPaid ? const Color(0xFFF0FDF4) : (isOverdue ? const Color(0xFFFEF2F2) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isPaid
                        ? const Color(0xFFBBF7D0)
                        : (isOverdue ? const Color(0xFFFCA5A5) : const Color(0xFFE2E8F0)),
                    width: (isPaid || isOverdue) ? 1.5 : 1.0,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isPaid ? Icons.check_circle : (isOverdue ? Icons.error_outline : Icons.calendar_month_outlined),
                          color: isPaid
                              ? const Color(0xFF16A34A)
                              : (isOverdue ? const Color(0xFFDC2626) : const Color(0xFF0F172A)),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'قسط شهر: ${m['month_key']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'موعد الاستحقاق: ${m['due_date']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          formatMoney(totalDue),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 12),
                        if (isPaid)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'تم السداد ✓',
                              style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          )
                        else
                          ElevatedButton(
                            onPressed: () => _payFullMonth(idx, scheduleIds),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isOverdue ? const Color(0xFFDC2626) : const Color(0xFF10B981),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: Text(
                              isOverdue ? 'سداد المتأخر' : 'سداد القسط',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// الشاشة 5: صفحة كروت المنتجات مع زر الحذف وتفاصيل موسعة
// -----------------------------------------------------------------------------
class CustomerProductsScreen extends StatefulWidget {
  final String customerName;
  final List<dynamic> contracts;

  const CustomerProductsScreen({super.key, required this.customerName, required this.contracts});

  @override
  State<CustomerProductsScreen> createState() => _CustomerProductsScreenState();
}

class _CustomerProductsScreenState extends State<CustomerProductsScreen> {
  late List<dynamic> _contracts;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _contracts = widget.contracts;
  }

  Future<void> _deleteContract(String contractId, String productName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('تأكيد حذف المنتج'),
            ],
          ),
          content: Text('هل أنت متأكد من إزالة منتج ($productName)؟ سيتم حذف جميع الأقساط الخاصة به نهائياً.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('إلغاء', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('إزالة نهائية', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true) return;

    try {
      final res = await http.delete(Uri.parse('https://installment-system-production.up.railway.app/contracts/$contractId/'));
      if (res.statusCode == 200) {
        setState(() {
          _contracts.removeWhere((c) => c['id'] == contractId);
          _hasChanges = true;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ تم حذف منتج ($productName) بنجاح'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );

        if (_contracts.isEmpty) {
          Navigator.pop(context, true);
        }
      } else {
        throw Exception("فشل حذف المنتج");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ أثناء الحذف: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showProductDetailsModal(BuildContext context, dynamic con) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        con['product_name'] ?? 'سلعة عامة',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  Text('رقم العقد: ${con['contract_number']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                  const Divider(height: 20),
                  _buildDetailLine('سعر الكاش الأصلي:', formatMoney(con['total_cash_price'])),
                  _buildDetailLine('المقدم المدفوع:', formatMoney(con['down_payment'])),
                  _buildDetailLine('مبلغ التمويل المقسط:', formatMoney(con['financed_amount'])),
                  _buildDetailLine('نسبة الفائدة السنوية:', '${con['interest_rate_percent']}%'),
                  _buildDetailLine('إجمالي العقد بالفائدة:', formatMoney(con['total_contract_amount'])),
                  const Divider(height: 16),
                  _buildDetailLine('القسط الشهري:', '${formatMoney(con['monthly_installment'])} / شهر', highlight: true),
                  _buildDetailLine('المدة الكلية للتقسيط:', '${con['months_count']} شهر'),
                  _buildDetailLine('الشهور المسددة:', '${con['paid_months']} شهر'),
                  _buildDetailLine('الشهور المتبقية:', '${con['remaining_months']} شهر'),
                  _buildDetailLine('المسدد نقداً حتى الآن:', formatMoney(con['paid_amount'])),
                  _buildDetailLine('المتبقي للسداد نقداً:', formatMoney(con['remaining_amount'])),
                  _buildDetailLine('تاريخ بداية التعاقد:', '${con['start_date']}'),
                  _buildDetailLine('موعد القسط القادم:', '${con['next_due_date']}'),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailLine(String title, String val, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
          Text(
            val,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: highlight ? const Color(0xFF059669) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'منتجات وعقود: ${widget.customerName}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          backgroundColor: const Color(0xFF0F172A),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
        ),
        body: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _contracts.length,
          itemBuilder: (context, index) {
            final con = _contracts[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.devices, color: Color(0xFF0F172A), size: 22),
                            const SizedBox(width: 8),
                            Text(
                              con['product_name'] ?? 'سلعة عامة',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                          tooltip: 'إزالة المنتج',
                          onPressed: () => _deleteContract(con['id'], con['product_name'] ?? ''),
                        ),
                      ],
                    ),
                    Text(
                      'رقم العقد: ${con['contract_number']}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                    const Divider(height: 20),

                    Row(
                      children: [
                        Expanded(child: _buildProductStat('الشهور المتبقية', '${con['remaining_months']} شهر', const Color(0xFF2563EB))),
                        Expanded(child: _buildProductStat('إجمالي السعر بالفائدة', formatMoney(con['total_contract_amount']), const Color(0xFF0F172A))),
                        Expanded(child: _buildProductStat('موعد القسط القادم', '${con['next_due_date']}', const Color(0xFF059669))),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final updated = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditContractScreen(contract: con),
                                ),
                              );
                              if (updated == true) {
                                setState(() {
                                  _hasChanges = true;
                                });
                                Navigator.pop(context, true);
                              }
                            },
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            label: const Text('تعديل البيانات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showProductDetailsModal(context, con),
                            icon: const Icon(Icons.visibility_outlined, size: 16, color: Colors.white),
                            label: const Text('التفاصيل الكاملة', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductStat(String title, String val, Color color) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// الشاشة 6: صفحة تعديل بيانات العقد
// -----------------------------------------------------------------------------
class EditContractScreen extends StatefulWidget {
  final dynamic contract;

  const EditContractScreen({super.key, required this.contract});

  @override
  State<EditContractScreen> createState() => _EditContractScreenState();
}

class _EditContractScreenState extends State<EditContractScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _productNameController;
  late TextEditingController _priceController;
  late TextEditingController _downPaymentController;
  late TextEditingController _interestRateController;
  late TextEditingController _monthsCountController;
  late DateTime _startDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _productNameController = TextEditingController(text: widget.contract['product_name'] ?? '');
    _priceController = TextEditingController(text: widget.contract['total_cash_price'].toString());
    _downPaymentController = TextEditingController(text: widget.contract['down_payment'].toString());
    _interestRateController = TextEditingController(text: widget.contract['interest_rate_percent'].toString());
    _monthsCountController = TextEditingController(text: widget.contract['months_count'].toString());
    
    try {
      _startDate = DateTime.parse(widget.contract['start_date']);
    } catch (_) {
      _startDate = DateTime.now();
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Directionality(textDirection: TextDirection.rtl, child: child!);
      },
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final contractId = widget.contract['id'];
      final body = jsonEncode({
        "product_name": _productNameController.text.trim(),
        "total_cash_price": double.tryParse(_priceController.text) ?? 0.0,
        "down_payment": double.tryParse(_downPaymentController.text) ?? 0.0,
        "interest_rate_percent": double.tryParse(_interestRateController.text) ?? 0.0,
        "months_count": int.tryParse(_monthsCountController.text) ?? 12,
        "start_date": _startDate.toIso8601String().split('T')[0],
      });

      final res = await http.put(
        Uri.parse('https://installment-system-production.up.railway.app/contracts/$contractId/'),
        headers: {"Content-Type": "application/json", "bypass-tunnel-reminder": "true"},
        body: body,
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ تم تعديل جميع بيانات المنتج وجدولة الأقساط بنجاح!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception("فشل حفظ التعديلات");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'تعديل عقد: ${widget.contract['contract_number']}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('تعديل البيانات الكاملة للعقد والتقسيط', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _productNameController,
                    decoration: const InputDecoration(
                      labelText: 'اسم المنتج / السلعة',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'اسم السلعة مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'إجمالي قيمة البيع كاش (ج.م)',
                      border: OutlineInputBorder(),
                      prefixText: 'ج.م ',
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'السعر مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _downPaymentController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المقدم المدفوع (ج.م)',
                      border: OutlineInputBorder(),
                      prefixText: 'ج.م ',
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'المقدم مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _interestRateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'النسبة المئوية السنوية للفائدة (%)',
                      border: OutlineInputBorder(),
                      suffixText: '%',
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'النسبة مطلوبة' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _monthsCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'عدد شهور التقسيط',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.timelapse),
                      suffixText: 'شهر',
                    ),
                    validator: (val) => val == null || val.isEmpty ? 'عدد الشهور مطلوب' : null,
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickStartDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Color(0xFF0F172A), size: 20),
                          const SizedBox(width: 10),
                          const Text('تاريخ بداية العقد / أول قسط:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          const Spacer(),
                          Text(
                            '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2563EB)),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _saveChanges,
                icon: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save_outlined, color: Colors.white),
                label: Text(
                  _isSaving ? 'جاري الحفظ...' : 'حفظ التعديلات وإعادة جدولة الأقساط',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}