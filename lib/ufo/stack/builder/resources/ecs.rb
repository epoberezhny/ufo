class Ufo::Stack::Builder::Resources
  class Ecs < Base
    def build
      attrs = {
        Type: "AWS::ECS::Service",
        Properties: properties
      }

      attrs[:DependsOn] = "Listener" if @create_elb

      attrs
    end

    def properties
      props = {
        Cluster: @cluster,
        DesiredCount: {
          "Fn::If": [
            "EcsDesiredCountIsBlank",
            {Ref: "AWS::NoValue"},
            {Ref: "EcsDesiredCount"}
          ]
        },
        LoadBalancers: {
          "Fn::If": [
            "CreateTargetGroupIsTrue",
            [
              {
                ContainerName: "web",
                ContainerPort: @container[:port],
                TargetGroupArn: {Ref: "TargetGroup"}
              }
            ],
            {
              "Fn::If": [
                "ElbTargetGroupIsBlank",
                [],
                [
                  {
                    ContainerName: "web",
                    ContainerPort: @container[:port],
                    TargetGroupArn: {Ref: "ElbTargetGroup"}
                  }
                ]
              ]
            }
          ]
        },
        SchedulingStrategy: {Ref: "EcsSchedulingStrategy"}
      }

      props[:TaskDefinition] = @rollback_definition_arn ? @rollback_definition_arn : {Ref: "TaskDefinition"}

      if @container[:network_mode].to_s == 'awsvpc'
        props[:NetworkConfiguration] = {
          AwsvpcConfiguration: {
            Subnets: {Ref: "EcsSubnets"},
            SecurityGroups: security_groups(:ecs)
          }
        }

        if @container[:fargate]
          props[:LaunchType] = "FARGATE"
          props[:NetworkConfiguration][:AwsvpcConfiguration][:AssignPublicIp] = "ENABLED" # Works with fargate but doesnt seem to work with non-fargate
        end
      end

      props
    end
  end
end
