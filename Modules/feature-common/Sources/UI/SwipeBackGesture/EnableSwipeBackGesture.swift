//
//  EnableSwipeBackGesture.swift
//  feature-common
//

public struct EnableSwipeBackGesture: UIViewControllerRepresentable {
  public init() {}
  
  public func makeUIViewController(context: Context) -> UIViewController {
    let controller = UIViewController()
    DispatchQueue.main.async {
      controller.navigationController?.interactivePopGestureRecognizer?.isEnabled = true
      controller.navigationController?.interactivePopGestureRecognizer?.delegate = nil
    }
    return controller
  }
  
  public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

public struct DisableSwipeBackGesture: UIViewControllerRepresentable {
  public init() { }
  
  public func makeUIViewController(context: Context) -> UIViewController {
    let controller = WrapperViewController()
    return controller
  }
  
  public func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
    if let navController = uiViewController.navigationController {
      navController.interactivePopGestureRecognizer?.isEnabled = false
    }
  }
  
  private class WrapperViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
      super.viewDidAppear(animated)
      navigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
      super.viewWillDisappear(animated)
      navigationController?.interactivePopGestureRecognizer?.isEnabled = true
    }
  }
}
