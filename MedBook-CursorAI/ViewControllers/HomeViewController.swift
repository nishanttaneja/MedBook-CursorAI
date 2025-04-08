import UIKit

class HomeViewController: BaseViewController {
    private let viewModel = AuthViewModel()
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "Welcome to MedBook"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Logout", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func setupUI() {
        super.setupUI()
        title = "Home"
        
        view.addSubview(welcomeLabel)
        view.addSubview(logoutButton)
        
        NSLayoutConstraint.activate([
            welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            welcomeLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            logoutButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            logoutButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            logoutButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        
        setupViewModel()
    }
    
    private func setupViewModel() {
        viewModel.onSuccess = { [weak self] in
            let landingVC = LandingViewController()
            self?.navigationController?.setViewControllers([landingVC], animated: true)
        }
    }
    
    @objc private func logoutTapped() {
        viewModel.logout()
    }
} 