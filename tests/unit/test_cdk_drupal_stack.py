import aws_cdk as core
import aws_cdk.assertions as assertions

from cdk_drupal.cdk_drupal_stack import CdkDrupalStack

# example tests. To run these tests, uncomment this file along with the example
# resource in cdk_drupal/cdk_drupal_stack.py
def test_sqs_queue_created():
    app = core.App()
    stack = CdkDrupalStack(app, "cdk-drupal")
    template = assertions.Template.from_stack(stack)

#     template.has_resource_properties("AWS::SQS::Queue", {
#         "VisibilityTimeout": 300
#     })
