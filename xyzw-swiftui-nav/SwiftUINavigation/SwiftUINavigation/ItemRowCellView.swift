import Combine
import UIKit

class ItemRowCellView: UICollectionViewListCell {
//  let viewModel: ItemRowViewModel
  private var cancellables: Set<AnyCancellable> = []

  override func prepareForReuse() {
    super.prepareForReuse()
    self.cancellables = []
  }

  func bind(
    viewModel: ItemRowViewModel,
    context: UIViewController
  ) {

    viewModel.$item
      .map(\.name)
      .removeDuplicates()
      .sink { [unowned self] name in
        var content = self.defaultContentConfiguration()
        content.text = name
        self.contentConfiguration = content
      }
      .store(in: &self.cancellables)

    var presentedViewController: UIViewController?

    viewModel.$route
      .removeDuplicates()
      .sink { route in
        switch route {
        case .none:

          if let presentedViewController = presentedViewController {
            presentedViewController.dismiss(animated: true)
            context.pop(viewController: presentedViewController)
          }

          presentedViewController = nil

          break

        case .deleteAlert:
          let alert = UIAlertController(
            title: viewModel.item.name,
            message: "Are are you sure you want to delete this item?",
            preferredStyle: .alert
          )
          alert.addAction(
            .init(
              title: "Cancel",
              style: .cancel,
              handler: { _ in
                viewModel.cancelButtonTapped()
              }
            )
          )
          alert.addAction(
            .init(
              title: "Delete",
              style: .destructive,
              handler: { _ in
                viewModel.deleteConfirmationButtonTapped()
              }
            )
          )
          context.present(alert, animated: true)
          presentedViewController = alert

        case let .duplicate(itemViewModel):
          let vc = ItemViewController(viewModel: itemViewModel)
          vc.title = "Duplicate"
          vc.navigationItem.leftBarButtonItem = .init(
            title: "Cancel",
            primaryAction: .init { _ in
              viewModel.cancelButtonTapped()
            }
          )
          vc.navigationItem.rightBarButtonItem = .init(
            title: "Add",
            primaryAction: .init { _ in
              viewModel.duplicate(item: itemViewModel.item)
            }
          )
          let nav = UINavigationController(rootViewController: vc)
          nav.modalPresentationStyle = .popover
          nav.popoverPresentationController?.sourceView = self
          context.present(nav, animated: true)
          presentedViewController = nav

        case let .edit(itemViewModel):
          let vc = ItemViewController(viewModel: itemViewModel)
          vc.title = "Edit"
          vc.navigationItem.leftBarButtonItem = .init(
            title: "Cancel",
            primaryAction: .init { _ in
              viewModel.cancelButtonTapped()
            }
          )
          vc.navigationItem.rightBarButtonItem = .init(
            title: "Save",
            primaryAction: .init { _ in
              viewModel.edit(item: itemViewModel.item)
            }
          )
          context.show(vc, sender: nil)
          presentedViewController = vc
        }
      }
      .store(in: &self.cancellables)
  }
}

extension UIViewController {
  func pop(viewController: UIViewController, animated: Bool = true) {
    if
       let nav = self.navigationController,
       let index = nav.viewControllers.firstIndex(of: viewController),
       index >= 1
    {
      nav.setViewControllers(
        Array(nav.viewControllers[...(index - 1)]),
        animated: true
      )
    }

  }
}
