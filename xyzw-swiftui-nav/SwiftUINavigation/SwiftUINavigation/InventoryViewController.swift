import Combine
import SwiftUI
import UIKit

class InventoryViewController: UIViewController {
  let viewModel: InventoryViewModel
  private var cancellables: Set<AnyCancellable> = []

  init(viewModel: InventoryViewModel) {
    self.viewModel = viewModel
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    // MARK: view creation

    self.navigationItem.rightBarButtonItem = .init(
      title: "Add",
      primaryAction: .init { [unowned self] _ in
        self.viewModel.addButtonTapped()
      }
    )
    self.title = "Inventory"

    // MARK: view model bindings

    var presentedViewController: UIViewController?

    self.viewModel.$route
      .removeDuplicates()
      .sink { [unowned self] route in
        switch route {
        case .none:
          presentedViewController?.dismiss(animated: true)
          break

        case let .add(itemViewModel):
          let vc = ItemViewController(viewModel: itemViewModel)
          vc.title = "Add"
          vc.navigationItem.leftBarButtonItem = .init(
            title: "Cancel",
            primaryAction: .init { _ in
              self.viewModel.cancelButtonTapped()
            }
          )
          vc.navigationItem.rightBarButtonItem = .init(
            title: "Add",
            primaryAction: .init { _ in
              self.viewModel.add(item: itemViewModel.item)
            }
          )
          let nav = UINavigationController(rootViewController: vc)
          self.present(nav, animated: true)
          presentedViewController = nav

        case .row:
          break
        }

      }
      .store(in: &self.cancellables)

    // MARK: UI actions

  }
}

struct InventoryViewController_Previews: PreviewProvider {
  static var previews: some View {
      ToSwiftUI {
        UINavigationController(
          rootViewController: InventoryViewController(viewModel: .init())
        )
      }
  }
}
