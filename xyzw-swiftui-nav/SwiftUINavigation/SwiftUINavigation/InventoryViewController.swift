import Combine
import SwiftUI
import UIKit

extension ItemRowViewModel: Hashable {
  static func == (lhs: ItemRowViewModel, rhs: ItemRowViewModel) -> Bool {
    lhs === rhs
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(self.item)
  }
}

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
    
    enum Section { case inventory }
    
    let cellRegistration = UICollectionView.CellRegistration<
      ItemRowCellView, ItemRowViewModel
    >.init { [unowned self] cell, indexPath, itemRowViewModel in
      cell.bind(viewModel: itemRowViewModel, context: self)
    }
    
    let collectionView = UICollectionView(
      frame: .zero,
      collectionViewLayout: UICollectionViewCompositionalLayout.list(using: .init(appearance: .insetGrouped))
    )
    collectionView.translatesAutoresizingMaskIntoConstraints = false

    let dataSource = UICollectionViewDiffableDataSource<Section, ItemRowViewModel>(
      collectionView: collectionView
    ) { collectionView, indexPath, itemRowViewModel in
      collectionView.dequeueConfiguredReusableCell(
        using: cellRegistration,
        for: indexPath,
        item: itemRowViewModel
      )
    }
    collectionView.dataSource = dataSource
    
    self.view.addSubview(collectionView)
    NSLayoutConstraint.activate([
      collectionView.topAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.topAnchor),
      collectionView.leadingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.leadingAnchor),
      collectionView.trailingAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.trailingAnchor),
      collectionView.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor),
    ])
    
    // MARK: view model bindings
    
    self.viewModel.$inventory
      .sink { inventory in
        var snapshot = NSDiffableDataSourceSnapshot<Section, ItemRowViewModel>()
        snapshot.appendSections([.inventory])
        snapshot.appendItems(inventory.elements, toSection: .inventory)
        dataSource.apply(snapshot, animatingDifferences: true)
      }
      .store(in: &self.cancellables)

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
          rootViewController: InventoryViewController(
            viewModel: .init(
              inventory: [
                .init(item: .init(name: "Keyboard", color: .red, status: .inStock(quantity: 1)))
              ],
              route: nil
            )
          )
        )
      }
  }
}
