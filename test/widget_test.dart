import 'package:flutter_test/flutter_test.dart';
import 'package:tuition_fee/models/student.dart';
import 'package:tuition_fee/models/batch.dart';
import 'package:tuition_fee/models/payment.dart';

void main() {
  group('Model Tests', () {
    test('Student model handles empty optional phone number correctly', () {
      final student = Student(
        id: '26001',
        name: 'Rahim Ahmed',
        studentClass: 'Class 10',
        phone: '', // Optional phone number
        monthlyFee: 1500.0,
        batchId: 'batch_01',
      );

      expect(student.id, '26001');
      expect(student.name, 'Rahim Ahmed');
      expect(student.phone, isEmpty);
      expect(student.monthlyFee, 1500.0);
    });

    test('Student model handles provided phone number', () {
      final student = Student(
        id: '26002',
        name: 'Karim Ullah',
        studentClass: 'Class 9',
        phone: '01700000000',
        monthlyFee: 1200.0,
        batchId: 'batch_01',
      );

      expect(student.phone, '01700000000');
    });

    test('Batch model creation', () {
      final batch = Batch(id: 'b1', name: 'Morning Batch');
      expect(batch.id, 'b1');
      expect(batch.name, 'Morning Batch');
    });

    test('Payment model creation', () {
      final now = DateTime.now();
      final payment = Payment(
        studentId: '26001',
        amount: 1500.0,
        date: now,
      );

      expect(payment.studentId, '26001');
      expect(payment.amount, 1500.0);
    });
  });
}
