kube-logout() {
    #   kubectl config unset users.$(kubectl config current-context)
    #   kubectl config unset contexts.$(kubectl config current-context)
    #   kubectl config delete-cluster $(kubectl config current-context)
    kubectl config unset current-context
}
