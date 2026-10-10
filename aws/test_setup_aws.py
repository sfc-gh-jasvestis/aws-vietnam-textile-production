import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from setup_aws import ident, names, topic_rule, TOPIC


class SetupAwsTests(unittest.TestCase):
    def test_names_are_scoped_to_prefix_account_region(self):
        n = names('vn-textile-production', '123456789012', 'us-west-2')
        self.assertEqual(n['bucket'], 'vn-textile-production-123456789012-us-west-2')
        self.assertEqual(n['storage_int'], 'VN_TEXTILE_PRODUCTION_S3_INT')
        self.assertEqual(n['iot_rule'], 'vn_textile_production_telemetry')

    def test_rejects_unsafe_identifiers(self):
        for bad in ['DB; DROP', 'a-b', '1abc', '']:
            with self.assertRaises(ValueError):
                ident(bad)

    def test_iot_requests_match_botocore_schema(self):
        import botocore.session
        from botocore.validate import ParamValidator
        session = botocore.session.get_session()
        rule = topic_rule('vn-textile-production-123456789012-us-west-2', 'arn:aws:iam::123456789012:role/x')
        for service, op, params in [
            ('iot', 'CreateTopicRule', {'ruleName': 'vn_textile_production_telemetry', 'topicRulePayload': rule}),
            ('iot-data', 'Publish', {'topic': TOPIC, 'qos': 1, 'payload': b'{}'}),
        ]:
            shape = session.get_service_model(service).operation_model(op).input_shape
            report = ParamValidator().validate(params, shape)
            self.assertFalse(report.has_errors(), report.generate_report())


if __name__ == '__main__':
    unittest.main()
