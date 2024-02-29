package utils

import (
	appsv1 "k8s.io/api/apps/v1"
	corev1 "k8s.io/api/core/v1"
)

// 向指定的pod里面注入容器（docker in docker）

var privileged = true

var dind = corev1.Container{
	Name:  "dind",
	Image: "docker.io/library/docker:20.10.12-dind",
	SecurityContext: &corev1.SecurityContext{
		Privileged: &privileged,
	},
}

func InjectDockerInDockerContainer(dp *appsv1.Deployment) *appsv1.Deployment {
	//for i,contariner:=dp.Spec.Template.Spec.Containers{}
	var newContainers []corev1.Container
	newContainers = append(newContainers, dind)
	newContainers = append(newContainers, dp.Spec.Template.Spec.Containers...)
	dp.Spec.Template.Spec.Containers = newContainers
	return dp
}
