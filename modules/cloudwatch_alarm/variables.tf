variable "alarm_name" {
  description = "The descriptive name for the alarm."
  type        = string
}

variable "comparison_operator" {
  description = "The arithmetic operation to use when comparing the specified statistic and threshold (e.g., GreaterThanThreshold, LessThanThreshold)."
  type        = string
}

variable "evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold."
  type        = number
}

variable "metric_name" {
  description = "The name for the alarm's associated metric."
  type        = string
}

variable "namespace" {
  description = "The namespace for the alarm's associated metric (e.g., AWS/ECS, AWS/EC2)."
  type        = string
}

variable "period" {
  description = "The period in seconds over which the specified statistic is applied."
  type        = number
}

variable "statistic" {
  description = "The statistic to apply to the alarm's associated metric (e.g., Average, Sum, Maximum)."
  type        = string
  default     = "Average"
}

variable "threshold" {
  description = "The value against which the specified statistic is compared."
  type        = number
}

variable "alarm_description" {
  description = "The description for the alarm."
  type        = string
  default     = null
}

variable "dimensions" {
  description = "The dimensions for the alarm's associated metric. Must be a map of key-value pairs."
  type        = map(string)
}

variable "alarm_actions" {
  description = "The list of actions to execute when this alarm transitions into an ALARM state from any other state. Each action is specified as an ARN."
  type        = list(string)
  default     = []
}
